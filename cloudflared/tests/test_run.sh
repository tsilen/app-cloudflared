#!/usr/bin/env bash
# Unit tests for cloudflared/rootfs/run.sh (option validation and arguments).
# SC1091: sourced files are resolved at runtime.
# SC2154: cloudflared_args and MOCK_LOG_LEVEL are set by the sourced scripts.
# shellcheck disable=SC1091,SC2154
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
export OPTIONS_FILE="${TMP_DIR}/options.json"

# shellcheck source=./bashio-mocks.sh
source "${ROOT_DIR}/tests/bashio-mocks.sh"
# shellcheck source=../rootfs/run.sh
source "${ROOT_DIR}/rootfs/run.sh"

VALID_TOKEN="eyJhIjoiMDEyMzQ1Njc4OWFiY2RlZiIsInQiOiJ0dW5uZWwtaWQiLCJzIjoic2VjcmV0In0="
TEST_FAILURES=0

write_options() {
    printf '%s' "$1" >"${OPTIONS_FILE}"
}

# Called inside the test subshell; exits it so later checks cannot mask a failure
fail() {
    echo "  $*"
    exit 1
}

# Runs prepare in a subshell and prints its exit code
prepare_rc() {
    (prepare >/dev/null 2>&1) && echo 0 || echo $?
}

run_test() {
    local rc=0
    unset TUNNEL_TOKEN
    ("$1") || rc=$?
    if [[ ${rc} -ne 0 ]]; then
        echo "FAIL: $1"
        TEST_FAILURES=$((TEST_FAILURES + 1))
    else
        echo "PASS: $1"
    fi
}

test_valid_token_sets_env_not_args() {
    write_options "{\"tunnel_token\": \"${VALID_TOKEN}\"}"
    prepare
    [[ "${TUNNEL_TOKEN}" == "${VALID_TOKEN}" ]] || fail "TUNNEL_TOKEN not exported"
    [[ "${cloudflared_args[*]}" != *"${VALID_TOKEN}"* ]] || fail "token leaked into arguments"
    [[ "${cloudflared_args[*]}" != *"--token"* ]] || fail "--token present"
    [[ "${cloudflared_args[*]}" == "--no-autoupdate --metrics=127.0.0.1:36500 --management-diagnostics=false run" ]] ||
        fail "unexpected args: ${cloudflared_args[*]}"
}

test_missing_token_fails() {
    write_options '{}'
    [[ "$(prepare_rc)" == "1" ]] || fail "missing token accepted"
}

test_null_token_fails() {
    write_options '{"tunnel_token": null}'
    [[ "$(prepare_rc)" == "1" ]] || fail "null token accepted"
}

test_whole_command_as_token_fails() {
    write_options "{\"tunnel_token\": \"cloudflared service install ${VALID_TOKEN}\"}"
    [[ "$(prepare_rc)" == "1" ]] || fail "command pasted as token accepted"
}

test_missing_options_file_fails() {
    rm -f "${OPTIONS_FILE}"
    [[ "$(prepare_rc)" == "1" ]] || fail "missing options file accepted"
}

test_post_quantum_and_run_parameters() {
    write_options "{\"tunnel_token\": \"${VALID_TOKEN}\", \"post_quantum\": true, \"run_parameters\": [\"--protocol=quic\", \"--loglevel=warn\"]}"
    prepare
    [[ "${cloudflared_args[*]}" == "--no-autoupdate --metrics=127.0.0.1:36500 --management-diagnostics=false --post-quantum --protocol=quic --loglevel=warn run" ]] ||
        fail "unexpected args: ${cloudflared_args[*]}"
}

test_post_quantum_false() {
    write_options "{\"tunnel_token\": \"${VALID_TOKEN}\", \"post_quantum\": false}"
    prepare
    [[ "${cloudflared_args[*]}" != *"--post-quantum"* ]] || fail "--post-quantum set although false"
}

test_debug_loglevel_rejected() {
    write_options "{\"tunnel_token\": \"${VALID_TOKEN}\", \"run_parameters\": [\"--loglevel=debug\"]}"
    [[ "$(prepare_rc)" == "1" ]] || fail "--loglevel=debug accepted (would log request headers)"
}

test_unlisted_parameter_rejected() {
    local parameter
    for parameter in "--metrics=0.0.0.0:36500" "--token=abc" "--logfile=/tmp/x" "--protocol=quic --metrics=0.0.0.0:1"; do
        write_options "{\"tunnel_token\": \"${VALID_TOKEN}\", \"run_parameters\": [\"${parameter}\"]}"
        [[ "$(prepare_rc)" == "1" ]] || fail "parameter accepted: ${parameter}"
    done
}

test_log_level_applied() {
    write_options "{\"tunnel_token\": \"${VALID_TOKEN}\", \"log_level\": \"debug\"}"
    prepare
    [[ "${MOCK_LOG_LEVEL}" == "debug" ]] || fail "log level not applied"
}

main() {
    run_test test_valid_token_sets_env_not_args
    run_test test_missing_token_fails
    run_test test_null_token_fails
    run_test test_whole_command_as_token_fails
    run_test test_missing_options_file_fails
    run_test test_post_quantum_and_run_parameters
    run_test test_post_quantum_false
    run_test test_debug_loglevel_rejected
    run_test test_unlisted_parameter_rejected
    run_test test_log_level_applied

    if [[ ${TEST_FAILURES} -ne 0 ]]; then
        echo "${TEST_FAILURES} test(s) failed."
        exit 1
    fi
    echo "All tests passed."
}

main
