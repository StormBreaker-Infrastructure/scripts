#!/usr/bin/env bash

# Copyright (C) 2020 Saalim Quadri (iamsaalim)
# SPDX-License-Identifier: Apache-2.0 license

# Exit is nothing is set
[[ $# = 0 ]] && echo "No Device Input" && exit 1

# Set Variables
DEVICE="$1"

commit-id() {
    echo "Checking commit-id of $DEVICE"
}

commit-id