#!/bin/bash

# Execute the main.sh script
./main.sh

CURRENT_SNAPSHOT=$(aws --profile prod --endpoint "$ENDPOINT" s3 ls "s3://forest-archive/mainnet/lite/" | sort | tail -n 1 | awk '{print $NF}')
CURRENT_EPOCH=$(echo "$CURRENT_SNAPSHOT" | awk -F'_' '{gsub(/[^0-9]/, "", $6); print $6}')

# Check if the main.sh script executed successfully
if [ $? -eq 0 ]; then
    # If successful, call notify.rb with "success"
    ruby notify.rb "$CURRENT_EPOCH" "success"
else
    # If failed, call notify.rb with "failure"
    ruby notify.rb "$CURRENT_EPOCH" "failure"
fi
