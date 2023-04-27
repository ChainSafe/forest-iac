#!/bin/bash
cd $BASE_FOLDER
flock -n /tmp/mainnet.lock -c "ruby daily_snapshot.rb mainnet > mainnet_log.txt"
