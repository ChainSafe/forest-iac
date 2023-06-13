#!/bin/bash

# Enable strict error handling and command tracing
set -ex

# Copy local source files in a folder together with ruby_common and create a zip archive.

cd "$1" || exit
cp --archive ../../../scripts/ruby_common service/ || exit

rm -f sources.tar
(cd service && tar cf ../sources.tar --sort=name --mtime='UTC 2019-01-01' ./* > /dev/null 2>&1) || exit
rm -fr service/ruby_common
echo "{ \"path\": \"$1/sources.tar\" }"
