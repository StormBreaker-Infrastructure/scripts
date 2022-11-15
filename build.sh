#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

# Exit is nothing is set
[[ $# = 0 ]] && echo "No Device Input" && exit 1

# Set Variables
DEVICE="$1"

fetch-commit-id() {
    echo "Checking commit-id of $DEVICE"
    echo "Fetching remote information of the device"
    COMMIT_ID_FETCH=$(git ls-remote https://github.com/stormbreaker-project/$DEVICE | head -1 | cut -f -1)
    echo $COMMIT_ID_FETCH
    compare-commit-id
}

compare-commit-id() {
    if [[ -f commit-id/$DEVICE-id ]]; then
		PREVIOUS_COMMIT_ID=$(cat commit-id/$DEVICE-id)
        if [ $COMMIT_ID_FETCH = $PREVIOUS_COMMIT_ID ]; then
            echo "No need to trigger the build"
        else
            echo "Triggering the build for $DEVICE"
            echo "$COMMIT_ID_FETCH" >> commit-id/$DEVICE-id
	    fi
    else
        echo "Warning: No previous configuration Found!"
        echo "Kindly push a commit to your kernel source."
        echo "Re-trigger the script after this step."
        echo "This is added to ensure no issues in script arguments."
        echo "$COMMIT_ID_FETCH" >> commit-id/$DEVICE-id
	fi
}

fetch-commit-id