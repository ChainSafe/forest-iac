#!/bin/bash

# Execute the main.sh script
./main.sh

# Check if the main.sh script executed successfully
if ./main.sh; then
    # If successful, call notify.rb with "success"
    ruby notify.rb "success"
else
    # If failed, call notify.rb with "failure"
    ruby notify.rb "failure"
fi
