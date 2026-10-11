#!/command/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant App: Cloudflared (hardened)
#
# Runs a remote-managed Cloudflare Tunnel using a tunnel token. Hostname routes
# and Access policies are configured in the Cloudflare Zero Trust dashboard.
#
# Options are read directly from /data/options.json, so the app does not need
# access to the Supervisor API or to the Home Assistant configuration folder.
# ==============================================================================

OPTIONS_FILE="${OPTIONS_FILE:-/data/options.json}"
METRICS_ADDRESS="127.0.0.1:36500"
TOKEN_REGEX='^[A-Za-z0-9+/=_-]{32,}$'
RUN_PARAMETER_REGEX='^(--(edge-bind-address|edge-ip-version|grace-period|ha-connections|protocol|region|retries|tag)=[^[:space:]]+|--loglevel=(info|warn|error|fatal))$'

declare -a cloudflared_args=()

# ------------------------------------------------------------------------------
# Prints an option value from the options file (arrays: one item per line).
# Prints nothing if the option is missing or null.
# ------------------------------------------------------------------------------
option() {
    jq -r --arg key "$1" \
        'if has($key) and .[$key] != null then .[$key] else empty end
         | if type == "array" then .[] else tostring end' \
        "${OPTIONS_FILE}"
}

# ------------------------------------------------------------------------------
# Validates the options and builds the cloudflared argument list.
# The tunnel token is exported as TUNNEL_TOKEN and never put on the command
# line or into the log.
# ------------------------------------------------------------------------------
prepare() {
    local log_level token run_parameter

    if [[ ! -r "${OPTIONS_FILE}" ]]; then
        bashio::exit.nok "Options file ${OPTIONS_FILE} is not readable"
    fi

    log_level="$(option log_level)"
    if [[ -n "${log_level}" ]]; then
        bashio::log.level "${log_level}"
    fi

    token="$(option tunnel_token)"
    if [[ -z "${token}" ]]; then
        bashio::exit.nok "'tunnel_token' is not set. Create a tunnel in the Cloudflare Zero Trust dashboard and paste its token into the app configuration."
    fi
    if ! [[ ${token} =~ ${TOKEN_REGEX} ]]; then
        bashio::exit.nok "'tunnel_token' does not look like a Cloudflare Tunnel token. Copy only the token (the long string after '--token'), not the whole command."
    fi
    export TUNNEL_TOKEN="${token}"
    unset token

    cloudflared_args=(
        --no-autoupdate
        --metrics="${METRICS_ADDRESS}"
        --management-diagnostics=false
    )

    if [[ "$(option post_quantum)" == "true" ]]; then
        cloudflared_args+=(--post-quantum)
    fi

    while IFS= read -r run_parameter; do
        [[ -z "${run_parameter}" ]] && continue
        if ! [[ ${run_parameter} =~ ${RUN_PARAMETER_REGEX} ]]; then
            bashio::exit.nok "Run parameter '${run_parameter}' is not allowed"
        fi
        cloudflared_args+=("${run_parameter}")
    done < <(option run_parameters)

    cloudflared_args+=(run)
}

main() {
    prepare
    bashio::log.info "Connecting Cloudflare Tunnel..."
    # Safe to log: the token is passed via the environment, not as an argument
    bashio::log.debug "cloudflared tunnel ${cloudflared_args[*]}"
    exec cloudflared tunnel "${cloudflared_args[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
