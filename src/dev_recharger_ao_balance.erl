%%% @doc AO-balance recharge-rate provider for `recharging-ledger@1.0'.
-module(dev_recharger_ao_balance).
-implements(<<"recharger-ao-balance@1.0">>).
-export([info/1, default/4]).

-define(DEFAULT_STATE_NODE, <<"https://state.forward.computer">>).
-define(DEFAULT_TOKEN_PROCESS, <<"0syT13r0s0tgPmIed95bJnuSqaD29HQNN8D3ElLSrsc">>).
-define(DEFAULT_BASE_RATE, 1).
-define(DEFAULT_BALANCE_STEP, 1_000_000_000_000).
-define(DEFAULT_RATE_STEP, 1).

info(_Opts) ->
    #{
        excludes => [
            <<"keys">>,
            <<"set">>,
            <<"remove">>,
            <<"state-node">>,
            <<"token-process">>,
            <<"base-rate">>,
            <<"balance-step">>,
            <<"rate-step">>
        ],
        default => fun default/4
    }.

default(AccountID, Msg, _Req, Opts) ->
    case balance(AccountID, Msg, Opts) of
        {ok, Balance} ->
            {ok, rate(Balance, Msg, Opts)};
        Error ->
            Error
    end.

balance(AccountID, Msg, Opts) ->
    Req = #{
        peer => hb_maps:get(<<"state-node">>, Msg, ?DEFAULT_STATE_NODE, Opts),
        path => path(AccountID, Msg, Opts),
        method => <<"GET">>,
        headers => #{},
        body => <<>>
    },
    case hb_http_client:request(Req, Opts) of
        {ok, 200, _Headers, Body} ->
            balance_from_body(Body);
        {ok, 404, _Headers, _Body} ->
            {ok, 0};
        {ok, Status, _Headers, _Body} ->
            {error, {balance_lookup_failed, Status}};
        {error, Reason} ->
            {error, Reason}
    end.

path(AccountID, Msg, Opts) ->
    TokenProcess =
        hb_maps:get(<<"token-process">>, Msg, ?DEFAULT_TOKEN_PROCESS, Opts),
    <<"/", TokenProcess/binary, "~process@1.0/compute/balances/", AccountID/binary>>.

balance_from_body(Body) ->
    case safe_nonnegative_int(trim(Body)) of
        {ok, _} = OK ->
            OK;
        _ ->
            {error, invalid_balance}
    end.

rate(Balance, Msg, Opts) ->
    BaseRate = int(<<"base-rate">>, Msg, ?DEFAULT_BASE_RATE, Opts),
    BalanceStep = pos_int(<<"balance-step">>, Msg, ?DEFAULT_BALANCE_STEP, Opts),
    RateStep = int(<<"rate-step">>, Msg, ?DEFAULT_RATE_STEP, Opts),
    BaseRate + ((Balance div BalanceStep) * RateStep).

int(Key, Msg, Default, Opts) ->
    case safe_nonnegative_int(hb_maps:get(Key, Msg, Default, Opts)) of
        {ok, Int} -> Int;
        error -> Default
    end.

pos_int(Key, Msg, Default, Opts) ->
    case int(Key, Msg, Default, Opts) of
        0 -> Default;
        Int -> Int
    end.

safe_nonnegative_int(Value) ->
    case hb_util:safe_int(Value) of
        {ok, Int} when Int >= 0 -> {ok, Int};
        _ -> error
    end.

trim(Bin) when is_binary(Bin) ->
    re:replace(Bin, <<"^\\s+|\\s+$">>, <<>>, [global, {return, binary}]).
