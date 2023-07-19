 #!/bin/bash

set -euxo pipefail

aria2c -x5 https://snapshots.calibrationnet.filops.net/minimal/latest.zst
