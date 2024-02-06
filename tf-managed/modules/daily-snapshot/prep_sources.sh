#!/bin/bash

# Enable strict error handling and command tracing
set -euxo pipefail

# Copy local source files in a folder together with ruby_common and create a zip archive.

cd "$1"
cp --archive "$2"/ruby_common service/

rm -f sources.tar
(cd service && tar cf ../sources.tar --sort=name --mtime='UTC 2019-01-01' ./* > /dev/null 2>&1)
rm -fr service/ruby_common
echo "{ \"path\": \"$1/sources.tar\" }"
