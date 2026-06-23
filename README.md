# recharger-ao-balance

Rate provider for `recharging-ledger@1.0`.

The ledger asks this device for an account's recharge rate. This device fetches
that account's AO balance and returns:

```text
base-rate + floor(balance / balance-step) * rate-step
```

The returned integer is the ledger's units-per-second recharge rate for that
account. It changes refill speed only; the ledger still owns capacity, balance,
and charging.

Default AO balance source:

```text
https://state.forward.computer/0syT13r0s0tgPmIed95bJnuSqaD29HQNN8D3ElLSrsc~process@1.0/compute/balances/<ACCOUNT>
```

Message keys:

```erlang
#{
    <<"device">> => <<"recharger-ao-balance@1.0">>,
    <<"base-rate">> => 0,
    <<"balance-step">> => 1_000_000_000_000,
    <<"rate-step">> => 1
}
```

Build:

```sh
rebar3 compile
rebar3 device package
```
