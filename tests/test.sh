#!/bin/bash

# Purpose: Execute test using data from foobar.txt

_exit_with_docker() {
  _ret="${1:0}"; shift
  echo >&2 ":: Removing container cnystb-$@..."
  docker rm -f "cnystb-$@"
  echo >&2 ":: (done)"
  return "$_ret"
}

# $1: Input file
_test() {
  local _file="${1:-}"
  local _basename="$(basename "$_file" .txt)"
  local _images=

  # See if input is provided with .txt extension
  if [[ "$(basename "$_file")" == "$_basename" ]]; then
    _file="$_file.txt"
  fi

  if [[ ! -f "$_file" ]]; then
    echo >&2 ":: File not found '$_file'. Return(1)."
    return 1
  fi

  echo >&2 ":: Generating 'tmp/$_basename.sh'..."
  ruby -n ./gen_tests.rb < "$_file" > "tmp/$_basename.sh"
  chmod 755 "tmp/$_basename.sh"

  bash -n "tmp/$_basename.sh"
  if [[ $? -ge 1 ]]; then
    return 1
  fi

  if [[ "${TESTS_DO_NOT_RUN:-}" == 1 ]]; then
    return 0
  fi

  _images="$(grep -m1 -E '^im ' "$_file")"
  _count=0
  for _img in $_images; do
    [[ $_img == "im" ]] && continue
    (( _count ++ ))
    echo >&2 ":: Testing $_basename with $_img"

    (
      docker run -d --name "cnystb-$_basename" -p 1888:8888 -e BTSYNC_PASSWD=admin "$_img" \
      || return 1

      docker ps -f "name=cnystb-$_basename" \
        | grep -q "cnystb-$_basename" \
        || {
          echo >&2 ":: Unable to start container cnystb-$_basename"
          return 1
        }

      cd ./tmp/ || _exit_with_docker 1 "$_basename"

      bash "$PWD/$_basename.sh" > "$_basename.${_img//\//-}.log"
    )

    if [[ $? -ge 1 ]]; then
      echo >&2 "FAIL: $_basename/$_img"
      _exit_with_docker 1 "$_basename"
    else
      _exit_with_docker 0 "$_basename"
    fi
  done

  if [[ $_count == 0 ]]; then
    echo >&2 "WARN: $_basename: Forget to specify 'im ' instruction?"
  fi
}

export PATH="$PWD/../:$PATH"
export BTSYNC_HOST="localhost:1888"
export BTSYNC_USER="admin"
export BTSYNC_PASSWD="admin"

while (( $# )); do
  _test $1 || exit 1
  shift
done
