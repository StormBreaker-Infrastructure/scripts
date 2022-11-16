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
    if [[ $COMMIT_ID_FETCH == "" ]]; then
        echo "Warning: Fetched commit id is empty!"
        echo "Did you enter the correct device name?"
    else
        compare-commit-id
    fi
}

compare-commit-id() {
    if [[ -f commit-id/$DEVICE-id ]]; then
		PREVIOUS_COMMIT_ID=$(cat commit-id/$DEVICE-id)
        rm commit-id/$DEVICE-id
        if [[ $PREVIOUS_COMMIT_ID == "" ]]; then
            echo "Warning: The cached commit-id is empty"
            echo "Did something went wrong?"
            echo "Removing the saved commit-id"
            rm commit-id/$DEVICE-id
        elif [ $COMMIT_ID_FETCH = $PREVIOUS_COMMIT_ID ]; then
            echo "No need to trigger the build"
            echo "If this is your first time triggering for a device"
            echo "Kindly push a commit to your kernel source."
        else
            echo "Triggering the build for $DEVICE"
            echo "$COMMIT_ID_FETCH" >> commit-id/$DEVICE-id
            set_build_variables
	    fi
    else
        echo "Warning: No previous configuration Found!"
        echo "Kindly push a commit to your kernel source."
        echo "Re-trigger the script after this step."
        echo "This is added to ensure no issues in script arguments."
        echo "$COMMIT_ID_FETCH" >> commit-id/$DEVICE-id
	fi
}

# Set repository variables
# This is done to ensure the above functions are executed.
set_build_variables() {
    CURRENT_DIR=$(pwd)
    DEVICE_DIR=$CURRENT_DIR/$DEVICE
    BUILD_DIR=$DEVICE_DIR
    clone_device
}

# Clone the device repository
clone_device() {
    GITHUB_ORG_lINK="https://github.com/stormbreaker-project"
    echo "Cloning device repository"
    git clone --depth=1 $GITHUB_ORG_lINK/$DEVICE $DEVICE  >/dev/null 2>&1 || cloneError

}

cloneError() {
    echo "Clone Failed!"
}

fetch-commit-id