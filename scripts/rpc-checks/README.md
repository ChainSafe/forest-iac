# rpc-checks

Verifies a Forest node's RPC responses against the [`chain.data.riba.plus`](https://chain.data.riba.plus)
dataset.

Methods checked: `eth_getBlockByNumber` (+ `eth_getTransactionByBlockNumberAndIndex`
for every archived tx), `eth_getBlockReceipts`, `eth_getLogs` (reference derived from
the receipts archive), `Filecoin.ChainGetTipSetByHeight`.

## Usage

```
check_rpc.rb [--only m1,m2,...] <network> <start_epoch> [end_epoch]
  methods: blocks, receipts, tipsets, logs (default: all)
  env:     FOREST_RPC_URL overrides the node URL (default localhost:2345/rpc/v1)
```

Exit codes (CI): `0` all pass · `1` any mismatch (dominates) · `2` no mismatches but an
archive day was unavailable (not yet published), so coverage is partial.

The node should run with `--no-gc`, or historical state may be pruned mid-run.

## Run locally

```sh
bundle install
bundle exec ruby check_rpc.rb calibnet 3865654 3871413
FOREST_RPC_URL=localhost:2347/rpc/v1 bundle exec ruby check_rpc.rb --only logs calibnet 3865787
```

## Run via Docker

```sh
docker build -t forest-rpc-checks .
# --network host so the container can reach the node on localhost:
docker run --rm --network host forest-rpc-checks calibnet 3865654 3865663
docker run --rm --network host -e FOREST_RPC_URL=localhost:2347/rpc/v1 \
  forest-rpc-checks --only receipts,logs calibnet 3865654 3865663
```
