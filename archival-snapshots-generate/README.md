# Archival snapshots generator
This tool will generate lite and diff snapshots provided a full snapshot.

# Installation
Install it with `cargo install --path .`. This tool also requires `forest-cli` in PATH. See more [here](https://github.com/ChainSafe/forest#installation).

```
Usage: archival-snapshots-generate [OPTIONS] <SNAPSHOT_FILE>

Arguments:
  <SNAPSHOT_FILE>  Full snapshot file to generate lite and diff snapshots from

Options:
      --network <NETWORK>                                            [default: calibnet]
      --lite-snapshot-every-n-epochs <LITE_SNAPSHOT_EVERY_N_EPOCHS>  [default: 30000]
      --lite-snapshot-depth <LITE_SNAPSHOT_DEPTH>                    [default: 2000]
      --diff-snapshots-between-lite <DIFF_SNAPSHOTS_BETWEEN_LITE>    [default: 10]
  -h, --help                                                         Print help
```
