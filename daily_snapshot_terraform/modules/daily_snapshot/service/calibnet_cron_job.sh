#!/bin/bash
cd $BASE_FOLDER
flock -n /tmp/calibnet.lock -c "ruby daily_snapshot.rb calibnet > calibnet_log.txt"
