#!/usr/bin/env bash
set -euo pipefail

export PATH="/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

APP_DIR="${APP_DIR:-/opt/recharger-ao-balance}"
cd "$APP_DIR"

: "${HB_CONFIG:=$APP_DIR/config.json}"
: "${HB_PRELOADED_STORE:=$APP_DIR/_build/preloaded-store}"

if [ -z "${HB_PRELOADED_DEVICES_INDEX:-}" ]; then
    HB_PRELOADED_DEVICES_INDEX="$(
        sed -n 's/.*<<"\([^"]*\)">>.*/\1/p' "$APP_DIR/_build/hb_preloaded_index.hrl"
    )"
fi

if [ -z "$HB_PRELOADED_DEVICES_INDEX" ]; then
    echo "missing HB_PRELOADED_DEVICES_INDEX; run: rebar3 device preload" >&2
    exit 1
fi

export HB_CONFIG
export HB_PRELOADED_STORE
export HB_PRELOADED_DEVICES_INDEX

exec erl \
    -pa "$APP_DIR"/_build/default/lib/*/ebin \
    -noshell \
    -eval 'case application:ensure_all_started(hb) of {ok, _} -> ok; {error, Reason} -> erlang:error(Reason) end, receive after infinity -> ok end.'
