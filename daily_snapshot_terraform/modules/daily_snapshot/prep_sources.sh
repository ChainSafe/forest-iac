#!/bin/bash

# Copy local source files in a folder together with ruby_common and create a zip archive.

cd "$1" || exit
cp -r ../../../scripts/ruby_common service/

(cd service && zip -r -X ../sources.zip . > /dev/null 2>&1)
rm -fr service/ruby_common
echo "{ \"path\": \"$1/sources.zip\" }"
