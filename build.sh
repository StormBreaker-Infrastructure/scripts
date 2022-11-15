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
    COMMIT_ID=$(git ls-remote https://github.com/stormbreaker-project/$DEVICE | head -1 | cut -f -1)
    echo $COMMIT_ID
    compare-commit-id
    echo "$COMMIT_ID" >> commit-id/$DEVICE-id
}

compare-commit-id() {
    echo "hello"
}

fetch-commit-id