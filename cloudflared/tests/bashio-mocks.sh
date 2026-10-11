# shellcheck shell=bash
# SC2034: MOCK_LOG_LEVEL is read by the test script that sources this file.
# shellcheck disable=SC2034
# Bashio helper mocks used for local shell unit tests.
# This file is intended to be sourced by shell test harnesses.

bashio::log.trace() { :; }
bashio::log.debug() { :; }
bashio::log.info() { :; }
bashio::log.notice() { :; }
bashio::log.warning() { :; }
bashio::log.error() { :; }

MOCK_LOG_LEVEL=""
bashio::log.level() {
    MOCK_LOG_LEVEL="$1"
}

bashio::exit.nok() {
    echo "ERROR: $*" >&2
    exit 1
}

bashio::exit.ok() {
    exit 0
}
