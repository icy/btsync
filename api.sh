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

## system utils

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

__perl_check() {
  perl -e 'use JSON' >/dev/null 2>&1 \
  || __exit "perl/JSON not found"
}

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

__token_get() {
  __curl_get "gui/token.html?t=$__now" \
    -X POST \
    -H "Cookie: GUID=${BTSYNC_COOKIE}" \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'Accept: */*' \
  | sed -e 's/[<>]/\n/g' \
  | grep -iE '[a-z0-9_-]{10,}'
}

__cookie_get() {
  __curl_get "gui/" -o /dev/null -c - \
  | grep GUID \
  | awk '{print $NF}'
  [[ "${PIPESTATUS[1]}" == "0" ]]
}

__exit() {
  echo "{\"error\": 900, \"message\": \"${@:-missing argument}\", \"at\": $__now}"
  exit 1
}

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
  __curl "getsyncfolders&discovery=1"
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
  __curl "getfoldersettings"
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

  _dir="$__tmp"

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
__validate_method $__method || __exit "unknown method"
__method="$(echo $__method | sed -e 's#/#_#g')"

for u in "$@"; do
  __BTSYNC_PARAMS="$u###$__BTSYNC_PARAMS"
done
export __BTSYNC_PARAMS="${__BTSYNC_PARAMS%###*}"

__BTSYNC_ECHO=: cookie_get || exit 1
__BTSYNC_ECHO=: token_get || exit 1

$__method "$@"
