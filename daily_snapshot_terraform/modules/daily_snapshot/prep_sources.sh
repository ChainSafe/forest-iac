#!/bin/bash

# Copy local source files in a folder together with ruby_common and create a zip archive.

cd $1
mkdir sources 2> /dev/null
cp -r ../../../scripts/ruby_common service/

(cd service; zip -r -X ../sources.zip * \
    %1>/dev/null %2>/dev/null)
rm -fr sources/ruby_common
echo "{ \"path\": \"$1/sources.zip\" }"
