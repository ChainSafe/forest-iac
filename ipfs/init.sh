#!/bin/sh

## Enable strict error handling, command tracing
set -eux

fetch_add() {
    # wget is available in ipfs/kubo image as part of BusyBox
    wget "$1" --no-verbose -O /tmp/.tmpfile
    ipfs add /tmp/.tmpfile
    rm /tmp/.tmpfile
}

## IPFS CID can be found in docker log, `docker logs forest-ipfs`

fetch_add https://github.com/filecoin-project/builtin-actors/releases/download/v9.0.3/builtin-actors-calibrationnet.car
fetch_add https://github.com/filecoin-project/builtin-actors/releases/download/v10.0.0-rc.1/builtin-actors-calibrationnet.car
fetch_add https://github.com/filecoin-project/builtin-actors/releases/download/v11.0.0-rc2/builtin-actors-calibrationnet.car
fetch_add https://github.com/filecoin-project/builtin-actors/releases/download/v9.0.3/builtin-actors-mainnet.car
fetch_add https://github.com/filecoin-project/builtin-actors/releases/download/v10.0.0/builtin-actors-mainnet.car
fetch_add https://github.com/filecoin-project/builtin-actors/releases/download/v11.0.0/builtin-actors-mainnet.car
