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

__debug() {
  if [[ "$BTSYNC_DEBUG" == "debug" ]]; then
    echo >&2 "(debug) $@"
  fi
}

# The most used `curl` method
__curl() {
  __debug "$FUNCNAME: $@"
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
  __debug "$FUNCNAME: $@"
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
  local _found=""

  while read _u; do
    [[ -n "$_u" ]] || continue
    echo "$_u" \
    | grep -qis "^$_section="
    if [[ $? -eq 0 ]]; then
      _found="$(echo "$_u" | sed -e "s/^$_section=//" | head -1)"
      break
    fi
  done \
    < <(echo "$__BTSYNC_PARAMS" | sed -e 's/###/\n/g' )

  echo "$_found"
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

# Return 0, 1 (valid), or default value (from $1, or 0)
__zero_or_one() {
  while read _line; do
    case "$_line" in
    "0"|"1") echo $_line ;;
    *) echo "${1:-0}" ;;
    esac
  done
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
  'folder/host/get') ;;
  'key/onetime/get') ;;
  'folder/setting/update') ;;
  'folder/host/create') ;;
  'folder/host/delete') ;;
  'folder/delete') ;;
  *) return 1;;
  esac
}

# This is as same as __folder_get, but for a single directory.
# Example usage
#   $0 directory_name
#   $0 -k key_string
# Note:
#   Multiple shared folders can share the same one-time secret key.
#   However, only one of them is active; other key will be put the
#   shared folder in 'pending status' (Pending receipt of master secret).
#   If this is the case, the first restul will be returned.
#   Looking up by key is not good.
__folder_get_single() {
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

  if [[ -n "$_dir" ]]; then
    __folder_get_single "$_dir" \
    | perl -e '
        use JSON;
        my $json = decode_json(<>);
        printf "%s|%s\n", $json->{"name"}, $json->{"secret"};
      '
  elif [[ -n "$_key" ]]; then
    __folder_get_single -k "$_key" \
    | perl -e '
        use JSON;
        my $json = decode_json(<>);
        printf "%s|%s\n", $json->{"name"}, $json->{"secret"};
      '
  else
    echo '-|-'
  fi
}

__key_push_and_pull() {
  local _random=
  local _key="$1" # should be a RW or ERW key
  local _nkey

  _random="$( \
    __curl "generatesecret" \
    | perl -e '
        use JSON;
        my $json = decode_json(<>);
        printf "%s\n", $json->{"secret"};
      '
    )"
  echo "$_random" | grep -Esq '^[A-Z2-7]{33}$'
  if [[ $? -ge 1 ]]; then
    echo "|"
    return
  fi

  ( export __BTSYNC_PARAMS="dir=/tmp/cnystb/$_random###key=$_key"; folder_create >/dev/null )

  _nkey="$( \
    export __BTSYNC_PARAMS="dir=/tmp/cnystb/$_random###key=$_key"
    folder_get \
    | perl -e '
        use JSON;
        my $json = decode_json(<>);
        my $secret = $json->{"secret"};
        my $rosecret = $json->{"readonlysecret"};
        printf "%s|%s\n", $secret, $rosecret;
      '
    )"

  echo "$_nkey"

  ( export __BTSYNC_PARAMS="dir=/tmp/cnystb/$_random###key=$_key"; folder_delete >/dev/null )
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

# Note: the first match wins!!!
folder_delete() {
  local _dir=
  local _key=

  _dir="$(__folder_get_name_and_key)"
  if [[ "$_dir" == "-|-" ]]; then
    __curl "getfoldersettings"
  else
    _key="${_dir##*|}"
    _dir="${_dir%%|*}"
    if [[ -n "$_key" && -n "$_dir" ]]; then
      __curl "removefolder&name=$_dir&secret=$_key"
    else
      __exit "Your key/path is not valid"
    fi
  fi
}

folder_setting_get() {
  local _dir=
  local _key=

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

# NOTE: `btsync` doesn't check for duplication
folder_host_create() {
  local _dir=
  local _key=
  local _addr="$(__input_fetch host)"
  local _port="$(__input_fetch port)"

  echo "$_addr" | grep -q ":"
  if [[ $? -eq 0 ]]; then
    _port="${_addr##*:}"
    _addr="${_addr%%:*}"
  fi

  if [[ -z "$_addr" || -z "$_port" ]]; then
    __exit "Port/Host must be specified"
  fi

  _dir="$(__folder_get_name_and_key)"
  if [[ "$_dir" == "-|-" ]]; then
    _exit "Folder path or key must be specified"
  else
    _key="${_dir##*|}"
    _dir="${_dir%%|*}"
    if [[ -n "$_key" && -n "$_dir" ]]; then
      __curl "addknownhosts&name=$_dir&secret=$_key&addr=$_addr&port=$_port" > /dev/null
      folder_host_get
    else
      __exit "Your key/path is not valid"
    fi
  fi
}

# NOTE: `btsync` doesn't check for duplication
folder_host_delete() {
  local _dir=
  local _key=
  local _addr="$(__input_fetch host)"
  local _port="$(__input_fetch port)"

  echo "$_addr" | grep -q ":"
  if [[ $? -eq 0 ]]; then
    _port="${_addr##*:}"
    _addr="${_addr%%:*}"
  fi

  if [[ -z "$_addr" || -z "$_port" ]]; then
    __exit "Port/Host must be specified"
  fi

  _dir="$(__folder_get_name_and_key)"
  if [[ "$_dir" == "-|-" ]]; then
    _exit "Folder path or key must be specified"
  else
    _key="${_dir##*|}"
    _dir="${_dir%%|*}"
    if [[ -n "$_key" && -n "$_dir" ]]; then
      folder_host_get \
      | perl -e '
          use JSON;
          my $check = shift(@ARGV);
          my $json = decode_json(<>);
          my $hosts = $json->{"hosts"};
          for (keys @{$hosts}) {
            my $h = $hosts->[$_];
            if ($check eq $h->{"peer"}) {
              print $h->{"index"} . "\n";
            }
          }
        ' -- "$_addr:$_port" \
      | while read _index; do
          __curl "removeknownhosts&name=$_dir&secret=$_key&index=$_index" >/dev/null
        done
      folder_host_get
    else
      __exit "Your key/path is not valid"
    fi
  fi
}

folder_setting_update() {
  local _dir=
  local _key=

  local _relay="$(__input_fetch   relay   | __zero_or_one 0)"
  local _tracker="$(__input_fetch tracker | __zero_or_one 0)"
  local _lan="$(__input_fetch     lan     | __zero_or_one 1)"
  local _dht="$(__input_fetch     dht     | __zero_or_one 0)"
  local _trash="$(__input_fetch   trash   | __zero_or_one 1)"
  local _host="$(__input_fetch    host    | __zero_or_one 1)"

  _dir="$(__folder_get_name_and_key)"
  if [[ "$_dir" == "-|-" ]]; then
    __exit "Key/Path must be specified"
  else
    _key="${_dir##*|}"
    _dir="${_dir%%|*}"
    if [[ -n "$_key" && -n "$_dir" ]]; then
      __curl "setfolderpref&name=$_dir&secret=$_key&usehosts=$_host&relay=$_relay&usetracker=$_tracker&searchlan=$_lan&searchdht=$_dht&deletetotrash=$_trash" >/dev/null
      folder_setting_get
    else
      __exit "Your key/path is not valid"
    fi
  fi
}

folder_host_get() {
  local _dir=
  local _key=

  _dir="$(__folder_get_name_and_key)"
  if [[ "$_dir" == "-|-" ]]; then
    __exit "Key/Path must be specified"
  else
    _key="${_dir##*|}"
    _dir="${_dir%%|*}"
    if [[ -n "$_key" && -n "$_dir" ]]; then
      __curl "getknownhosts&name=$_dir&secret=$_key"
    else
      __exit "Your key/path is not valid"
    fi
  fi
}

# Generate a key-pair, or generate a ro.key from rw.key
# For encryption support, please read the following article
#   http://antimatrix.org/BTSync/BTSync_Notes.html#encrypted_folders
key_get() {
  local _key="$(__input_fetch key)"
  local _encrypt="$(__input_fetch encrypt | __zero_or_one 0)"

  if [[ "${_key:0:1}" == "D" ]]; then
    _encrypt=1
  fi

  # Generate a new key-pair and return
  if [[ -z "$_key" ]]; then
    if [[ "$_encrypt" == 0 ]]; then
      __curl "generatesecret"
      return
    fi

    _key="$( \
      __curl "generatesecret" \
      | perl -e '
          use JSON;
          my $json = decode_json(<>);
          printf "%s\n", $json->{"secret"};
        '
      )"
    echo "$_key" | grep -Esq '^[A-Z2-7]{33}$'
    if [[ $? -ge 1 ]]; then
      __exit "Unable to generate a random key (the first phase)"
    fi
  fi

  if [[ "$_encrypt" == 1 ]]; then
    _key="D${_key:1:33}"
  fi

  _key="$(__key_push_and_pull $_key)"
  if [[ "$_key" == "|" ]]; then
    __exit "Unable to generate new key. Your key may not be valid."
  else
    _rokey="${_key##*|}"
    _key="${_key%%|*}"
    if [[ -z "$_rokey" ]]; then
      _rokey="$_key"
    fi
    if [[ "$_encrypt" == 1 ]]; then
      _erokey="F${_rokey:1:32}"
      echo "{\"secret\": \"${_key%%|*}\", \"rosecret\": \"${_rokey}\", \"erosecret\": \"${_erokey}\"}"
    else
      echo "{\"secret\": \"${_key%%|*}\", \"rosecret\": \"${_rokey}\"}"
    fi
  fi
}

key_onetime_get() {
  local _dir=
  local _key=

  _dir="$(__folder_get_name_and_key)"
  if [[ "$_dir" == "-|-" ]]; then
    __exit "Key/Path must be specified"
  else
    _key="${_dir##*|}"
    _dir="${_dir%%|*}"
    if [[ -n "$_key" && -n "$_dir" ]]; then
      __curl "generateroinvite&name=$_dir&secret=$_key"
    else
      __exit "Your key/path is not valid"
    fi
  fi
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

__perl_check

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
