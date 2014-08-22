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

__BTSYNC_ECHO=: cookie_get || exit 1
__BTSYNC_ECHO=: token_get || exit 1

$__method "$@"
