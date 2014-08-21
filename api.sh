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
export __agent="User-Agent: Mozilla/9.0 (X11; Linux x86_64; rv:99.0) Gecko/30100101 Firefox/31.0"

unset  __BTSYNC_ECHO

## system utils

__curl() {
  local _section="$1"; shift

  ${BTSYNC_CURL:-curl} -Ls \
    "http://$BTSYNC_HOST/$_section" \
    -u "$__user:$__pass" \
    -X POST \
    -H "Host: $BTSYNC_HOST" \
    -H "Referer: http://$BTSYNC_HOST/gui/" \
    -H "User-Agent: $__agent" \
    -H "Cookie: GUID=${BTSYNC_COOKIE}" \
    -H 'X-Requested-With: XMLHttpRequest' \
    -H 'Accept-Language: en-US,en;q=0.5' \
    "$@"
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

## internal methods

__token_get() {
  __BTSYNC_ECHO=: cookie_get || return 1

  __curl "gui/token.html?t=$__now" \
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
  echo "{\"error\": \"${@:-missing argument}\", \"at\": $__now}"
  exit 1
}

## exporting

__validate_method() {
  case "$@" in
  'token/get') ;;
  'curl/header/get') ;;
  'cookie/get') ;;
  'folder/get') ;;
  *) return 1;;
  esac
}

## puplic method

curl_header_get() {
  __BTSYNC_ECHO=: cookie_get || return 1
  __BTSYNC_ECHO=: token_get || return 1
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
  __BTSYNC_ECHO=: cookie_get || return 1

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
  __BTSYNC_ECHO=: cookie_get || return 1
  __BTSYNC_ECHO=: token_get || return 1

  __curl \
    "gui/?token=$BTSYNC_TOKEN&action=getsyncfolders&discovery=1&t=$__now" \
    -H 'Accept: application/json, text/javascript, */*; q=0.01'
}

__method="${1:-__exit}" ; shift
__validate_method $__method || __exit "unknown method"

__method="$(echo $__method | sed -e 's#/#_#g')"

$__method "$@"
