#!/bin/bash

# do not expand glob in this shell script
set -f

BASE="${INPUT_PATH:-.}"
POLICY="${INPUT_POLICY:-policy}"
FILES=( ${INPUT_FILES} )
MATCHES=( ${INPUT_MATCHES} )
NAMESPACE="${INPUT_NAMESPACE}"
DATA="${INPUT_DATA}"
ALL_NAMESPACES="${INPUT_ALL_NAMESPACES:-false}"

match() {
  local arg=${1}
  if [[ ${#MATCHES[@]} == 0 ]]; then
    return 0
  fi
  local match
  for match in ${MATCHES[@]}
  do
    if [[ ${arg} == ${match} ]]; then
      return 0
    fi
  done
  return 1
}

run_conftest() {
  local file

  local -a flags
  local -a files

  if [[ -n ${NAMESPACE} ]]; then
    flags+=(--namespace ${NAMESPACE})
  fi

  echo "[DEBUG] data: ${DATA}" >&2
  if [[ -n ${DATA} ]]; then
    flags+=(--data ${DATA})
  fi

  if ${ALL_NAMESPACES}; then
    flags+=(--all-namespaces)
  fi

  for file in "${FILES[@]}"
  do
    if ! match ${file}; then
      echo "[DEBUG] ${file}: against the matches condition, so skip it" >&2
      continue
    fi
    files+=("$file")
  done

  if [[ ${#files[@]} == 0 ]]; then
    echo "[DEBUG] no files to be passed to conftest"
    return 0
  fi

  echo "[DEBUG] flags: ${flags}" >&2
  echo "[DEBUG] files: ${files}" >&2

  conftest test ${flags[@]} \
    --no-color --output table \
    --policy "${POLICY}" \
    "${files[@]}"
}

main() {
  local -i status

  run_conftest "$@" | tee -a result
  status=${?}

  result="$(cat result)"
  # https://github.community/t5/GitHub-Actions/set-output-Truncates-Multiline-Strings/td-p/37870
  echo "::set-output name=result::${result//$'\n'/'%0A'}"

  return ${status}
}

set -o pipefail

main "$@"
exit $?
