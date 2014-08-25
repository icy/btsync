#!/bin/bash

# Purpose: I don't know
# Author : It's me, Anh K. Huynh
# Date   : Today, 2018 Aug 21st
# License: MIT

export BTSYNC_TOKEN="${BTSYNC_TOKEN:-}"
export BTSYNC_COOKIE="${BTSYNC_COOKIE:-}"
export BTSYNC_HOST="${BTSYNC_HOST:-localhost:8888}"

export __now="$(date +%s)"
export __user="${BTSYNC_USER:-admin}"
export __pass="${BTSYNC_PASSWD:-foobar}"
export __agent="btsync/cnystb bash binding"

unset  __BTSYNC_ECHO
unset  __BTSYNC_PARAMS
unset  __BTSYNC_PERL_OK

## system utils

# The most used `curl` method
__curl() {
  local _action="$1"; shift

  ${BTSYNC_CURL:-curl} -Ls \
    "http://$BTSYNC_HOST/gui/?token=$BTSYNC_TOKEN&action=$_action&t=$__now" \
    -u "$__user:$__pass" \
    -X POST \
    -H "Host: $BTSYNC_HOST" \
    -H "Referer: http://$BTSYNC_HOST/gui/" \
    -H "User-Agent: $__agent" \
    -H "Cookie: GUID=${BTSYNC_COOKIE}" \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    -H 'Accept: application/json, text/javascript, */*; q=0.01' \
    "$@"

  echo
}

# A simple GET query
__curl_get() {
  local _section="$1"; shift

  ${BTSYNC_CURL:-curl} -Ls \
    "http://$BTSYNC_HOST/$_section" \
    -u "$__user:$__pass" \
    -X GET \
    -H "Host: $BTSYNC_HOST" \
    -H "Referer: http://$BTSYNC_HOST/gui/" \
    -H "User-Agent: $__agent" \
    "$@"
}

# Check if `perl/JSON` is working. If `not`, __exit
__perl_check() {
  [[ -z "$__BTSYNC_PERL_OK" ]] || return 0

  perl -e 'use JSON' >/dev/null 2>&1 \
  || __exit "perl/JSON not found"
  export __BTSYNC_PERL_OK=1
}

# Read user input from $__BTSYNC_PARAMS. This variable is a list
# of user's input, separated by a `###` group. Example
#   foobar###dir=/path/to/###
#
# To get the `dir` variable, this method is invoked like this
#   __input_fetch dir
#
__input_fetch() {
  local _section="$1"

  echo "$__BTSYNC_PARAMS" \
  | sed -e 's/###/\n/g' \
  | while read _u; do
      [[ -n "$_u" ]] || continue
      echo "$_u" \
      | grep -qis "^$_section="
      if [[ $? -eq 0 ]]; then
        echo "$_u" | sed -e "s/^$_section=//"
        break
      fi
    done
}

# Encode the URL before using it in `curl`.
# See https://gist.github.com/moyashi/4063894
__url_encode() {
  awk '
    BEGIN {
      for (i = 0; i <= 255; i++) {
        ord[sprintf("%c", i)] = i
      }
    }

    function escape(str, c, len, res) {
      len = length(str)
      res = ""
      for (i = 1; i <= len; i++) {
        c = substr(str, i, 1);
        if (c ~ /[0-9A-Za-z]/)
          res = res c
        else
          res = res "%" sprintf("%02X", ord[c])
        }
      return res
    }

    {
      print escape($0)
    }
    '
}

## internal methods

# Return the token a valid token for the session
__token_get() {
  __curl_get "gui/token.html?t=$__now" \
    -X POST \
    -H "Cookie: GUID=${BTSYNC_COOKIE}" \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'Accept: */*' \
  | sed -e 's/[<>]/\n/g' \
  | grep -iE '[a-z0-9_-]{10,}'
}

# Return the cookie for the session
__cookie_get() {
  __curl_get "gui/" -o /dev/null -c - \
  | grep GUID \
  | awk '{print $NF}'
  [[ "${PIPESTATUS[1]}" == "0" ]]
}

# Print error message in JSON format, and exit(1)
__exit() {
  echo "{\"error\": 900, \"message\": \"${@:-missing argument}\", \"at\": $__now}"
  exit 1
}

# Fetch `dir` variable from user' input. This calls `__input_fetch` method
# and does some check to make sure `dir` is valid.
__input_fetch_dir() {
  local _dir

  _dir="$(__input_fetch dir)"
  if [[ -z "$_dir" ]]; then
    __exit "Missing argument. Please specify dir=<something>"
  fi

  if [[ "${_dir:0:1}" != "/" ]]; then
    __exit "Directory name be started by a slash. Otherwise, new directory may be created in a random place."
  fi

  echo $_dir | __url_encode
}

# Fetch `key` from user' input, or generate new key pair
# by invoking `key_get` method.
__input_fetch_key() {
  local _key="$(__input_fetch key)"

  __perl_check

  if [[ -z "$_key" ]]; then
    _key="$( \
    key_get \
    | perl -e '
        use JSON;
        my $pair = decode_json(<>);
        my $rwkey = $pair->{"secret"};
        print $rwkey . "\n";
      '
    )"
  fi

  echo $_key | __url_encode
}

## exporting

# Valide if input method is valid
__validate_method() {
  case "$@" in
  'token/get') ;;
  'curl/header/get') ;;
  'cookie/get') ;;
  'folder/get') ;;
  'setting/get') ;;
  'folder/setting/get') ;;
  'os/type/get') ;;
  'version/get') ;;
  'speed/get') ;;
  'key/get') ;;
  'os/dir/create') ;;
  'folder/create') ;;
  *) return 1;;
  esac
}

# This is as same as __folder_get, but for a single directory.
# Example usage
#   $0 directory_name
#   $0 -k key_string
__folder_get_single() {
  __perl_check

  __curl "getsyncfolders&discovery=$_discovery" \
  | perl -e '
    use JSON;

    my $dir = shift(@ARGV);
    my $key;
    my $option = 0;
    if ($dir eq "-k") {
      $key = shift(@ARGV);
      $option = 1;
    }
    my $jS0n = do { local $/; <STDIN> };
    my $json = decode_json( $jS0n );
    my $folders = $json->{"folders"};

    if ($option eq 0) {
      $dir =~ s/\/+$//;
      for ( keys @{$folders} ) {
        my $d = $folders->[$_];
        my $dname = $d->{"name"};
        $dname =~ s/\/+$//;
        if ($dname eq $dir) {
          print encode_json($d);
          print "\n";
          exit(0);
        }
      }
    }
    else {
      for ( keys @{$folders} ) {
        my $d = $folders->[$_];
        if ($d->{"secret"} eq $key || $d->{"readonlysecret"} eq $key) {
          print encode_json($d);
          print "\n";
          exit(0);
        }
      }
    }

    print "{\"error\": 900, \"message\": \"The path you specified is not valid.\"}\n";
    exit 1;
  ' \
    -- "$@"
}

__folder_get_name_and_key() {
  local _dir="$(__input_fetch dir)"
  local _key="$(__input_fetch key)"

  if [[ -n "$_key" ]]; then
    __folder_get_single -k "$_key" \
    | perl -e '
        use JSON;
        my $json = decode_json(<>);
        printf "%s|%s\n", $json->{"name"}, $json->{"secret"};
      '
  elif [[ -n "$_dir" ]]; then
    __folder_get_single "$_dir" \
    | perl -e '
        use JSON;
        my $json = decode_json(<>);
        printf "%s|%s\n", $json->{"name"}, $json->{"secret"};
      '
  else
    echo '-|-'
  fi
}

## puplic method

curl_header_get() {
  echo "{\"cookie\": \"$BTSYNC_COOKIE\", \"token\": \"$BTSYNC_TOKEN\", \"at\": $__now}"
}

cookie_get() {
  BTSYNC_COOKIE="${1:-$BTSYNC_COOKIE}"
  if [[ -z "$BTSYNC_COOKIE" ]]; then
    export BTSYNC_COOKIE="$(__cookie_get)"
    if [[ -z "$BTSYNC_COOKIE" ]]; then
      __exit "unable to get cookie"
    else
      ${__BTSYNC_ECHO:-echo} "{\"cookie\": \"$BTSYNC_COOKIE\", \"at\": $__now}"
    fi
  else
    ${__BTSYNC_ECHO:-echo} "{\"cookie\": \"$BTSYNC_COOKIE\"}, \"at\": $__now}"
  fi
}

token_get() {
  BTSYNC_TOKEN="${1:-$BTSYNC_TOKEN}"
  if [[ -z "$BTSYNC_TOKEN" ]]; then
    export BTSYNC_TOKEN="$(__token_get)"
    if [[ -z "$BTSYNC_TOKEN" ]]; then
      __exit "unable to get token"
    else
      ${__BTSYNC_ECHO:-echo} "{\"token\": \"$BTSYNC_TOKEN\", \"at\": $__now}"
    fi
  else
    ${__BTSYNC_ECHO:-echo} "{\"token\": \"$BTSYNC_TOKEN\"}, \"at\": $__now}"
  fi
}

folder_get() {
  local _discovery="$(__input_fetch discovery)"
  local _dir="$(__input_fetch dir)"
  local _key="$(__input_fetch key)"

  _discovery="${_discovery:-1}"

  if [[ -n "$_key" ]]; then
    __folder_get_single -k "$_key"
  elif [[ -n "$_dir" ]]; then
    __folder_get_single "$_dir"
  else
    __curl "getsyncfolders&discovery=$_discovery"
  fi
}

setting_get() {
  __curl "getsettings"
}

os_type_get() {
  __curl "getostype"
}

version_get() {
  __curl "getversion"
}

folder_setting_get() {
  local _discovery="$(__input_fetch discovery)"
  local _dir=
  local _key=

  [[ -n "$_dir" || -n "$_key" ]] && _get_default=0

  _discovery="${_discovery:-1}"

  _dir="$(__folder_get_name_and_key)"
  if [[ "$_dir" == "-|-" ]]; then
    __curl "getfoldersettings"
  else
    _key="${_dir##*|}"
    _dir="${_dir%%|*}"
    if [[ -n "$_key" && -n "$_dir" ]]; then
      __curl "getfolderpref&name=$_dir&secret=$_key"
    else
      __exit "Your key/path is not valid"
    fi
  fi
}

key_get() {
  __curl "generatesecret"
}

os_dir_create() {
  local _dir

  _dir="$(__input_fetch_dir)" \
  || { echo "$_dir"; exit 1; }

  __curl "adddir&dir=$_dir"
}

folder_create() {
  local _dir __tmp
  local _key

  __perl_check

  _dir="$(os_dir_create)"
  if [[ $? -ge 1 ]]; then
    echo "$_dir"
    exit 1
  fi

  __tmp="$(echo "$_dir" \
    | perl -e '
        use JSON;
        my $dir = decode_json(<>);
        my $path = $dir->{"path"};
        if ($dir->{"error"} ne "") {
          exit 1;
        } else {
          print $path;
        }
      '
    )"

  if [[ -z "$__tmp" ]]; then
    echo "$_dir"
    exit
  fi

  _dir="$(echo "$__tmp" | __url_encode)"

  _key="$(__input_fetch_key)"
  if [[ "$?" -ge 1 ]]; then
    __exit "Unable to read/create secret key."
  fi

  __tmp="$(__curl "addsyncfolder&new=1&secret=$_key&name=$_dir")"
  echo "$__tmp" \
  | perl -e '
      use JSON;
      my $output = decode_json(<>);
      if ($output->{"error"} ne "0") {
        exit 1;
      }
    '

  if [[ $? -ge 1 ]]; then
    echo "$__tmp"
  else
    echo "$__tmp"
  fi
}

speed_get() {
  __perl_check
  folder_get \
  | perl -e '
      use JSON;
      my $jS0n = do { local $/; <STDIN> };
      my $json = decode_json( $jS0n );
      my $recv_speed = $json->{"recv_speed"};
      my $send_speed = $json->{"send_speed"};
      my $speed = $json->{"speed"};
      printf "{\"recv_speed\": \"%s\", \"send_speed\": \"%s\", \"speed\": \"%s\"}\n",
        $recv_speed, $send_speed, $speed;
  '
}

## main routine

__method="${1:-__exit}" ; shift
__validate_method $__method || __exit "unknown method '$__method'"
__method="$(echo $__method | sed -e 's#/#_#g')"

for u in "$@"; do
  __BTSYNC_PARAMS="$u###$__BTSYNC_PARAMS"
done
export __BTSYNC_PARAMS="${__BTSYNC_PARAMS%###*}"

__BTSYNC_ECHO=: cookie_get || exit 1
__BTSYNC_ECHO=: token_get || exit 1

$__method "$@"
