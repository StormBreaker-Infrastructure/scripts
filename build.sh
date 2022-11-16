#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

# Exit is nothing is set
[[ $# = 0 ]] && echo "No Device Input" && exit 1

# Set Variables
# Common vars
KBUILD_BUILD_HOST="Stormbot"
KBUILD_BUILD_USER="StormCI"
DEVICE="$1"

fetch-commit-id() {
    echo "Checking commit-id of $DEVICE"
    echo "Fetching remote information of the device"
    COMMIT_ID_FETCH=$(git ls-remote https://github.com/stormbreaker-project/$DEVICE | head -1 | cut -f -1)
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
            echo ""
            echo "Warning: The cached commit-id is empty"
            echo "Did something went wrong?"
            echo "Removing the saved commit-id"
            echo ""
            rm commit-id/$DEVICE-id
        elif [ $COMMIT_ID_FETCH = $PREVIOUS_COMMIT_ID ]; then
            echo ""
            echo "No need to trigger the build"
            echo "If this is your first time triggering for a device"
            echo "Kindly push a commit to your kernel source."
            echo ""
        else
            echo ""
            echo "Triggering the build for $DEVICE"
            echo "$COMMIT_ID_FETCH" >> commit-id/$DEVICE-id
            set_build_variables
	    fi
    else
        echo ""
        echo "Warning: No previous configuration Found!"
        echo "Kindly push a commit to your kernel source."
        echo "Re-trigger the script after this step."
        echo "This is added to ensure no issues in script arguments."
        echo ""
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
    if [[ -f $DEVICE/Makefile ]]; then
        kernelVersion
        triggerBuild
    else
        echo ""
        echo "Something went wrong while cloning."
        echo ""
    fi
}

kernelVersion() {
	KERNEL_VERSION="$( cat $DEVICE/Makefile | grep VERSION | head -n 1 | sed "s|.*=||1" | sed "s| ||g" )"
    KERNEL_PATCHLEVEL="$( cat $DEVICE/Makefile | grep PATCHLEVEL | head -n 1 | sed "s|.*=||1" | sed "s| ||g" )"
    VERSION="${KERNEL_VERSION}.${KERNEL_PATCHLEVEL}"
    echo $VERSION

}

cloneGCC() {
	git clone --depth=1 https://github.com/stormbreaker-project/aarch64-linux-android-4.9 $TC_DIR/gcc >/dev/null 2>&1
	git clone --depth=1 https://github.com/stormbreaker-project/arm-linux-androideabi-4.9 $TC_DIR/gcc_32 >/dev/null 2>&1
}

cloneClang11() {
    git clone --depth=1 -b aosp-11.0.5 https://github.com/sohamxda7/llvm-stable $TC_DIR/clang >/dev/null 2>&1
	export KBUILD_COMPILER_STRING="$(${TC_DIR}/clang/bin/clang --version | head -n 1 | sed -e 's/  */ /g' -e 's/[[:space:]]*$//'))"
}

cloneCompiler() {
    TC_DIR=$CURRENT_DIR
    echo "Cloning Compilers"
    cloneGCC
    cloneClang11
    echo "Setting up PATH"
    PATH="${TC_DIR}/clang/bin:${TC_DIR}/gcc/bin:${TC_DIR}/gcc_32/bin:${PATH}"
    echo KBUILD_COMPILER_STRING
    $CURRENT_DIR/clang/bin/clang --version
}

buildFail() {
    BUILD_FAIL=true
    setStatus
    genJSON
}

buildPass() {
    BUILD_PASS=true
    setStatus
    genJSON
}

setStatus() {
    if [[ "$BUILD_FAIL" == "true" ]]; then
        STATUS="Failed"
    elif [[ "$BUILD_PASS" == "true" ]]; then
        STATUS="Passing"
    else
        STATUS="Undefined"
    fi
}

genJSON() {
    END=$(date +"%s")
    DIFF=$(($END - $START))
    echo $DIFF
    echo "Generating JSON"
    BRANCH="main" # Default branch of the repositories
    # TIME="$((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
    TIME="$DIFF seconds"
    COMMIT_ID=$(git log --oneline -1 | cut -f 1 -d " ")
    GEN_JSON_BODY=$(jq --null-input \
                    --arg device "$DEVICE" \
                    --arg branch "$BRANCH" \
                    --arg status "$STATUS" \
                    --arg build "$TIME" \
                    --arg commit "$COMMIT_ID" \
                    "{"device": \"$DEVICE\", "branch": \"$BRANCH\", "status": \"$STATUS\", "time": \"$TIME\", "commit": \"$COMMIT_ID\"}")
    echo $GEN_JSON_BODY
    cd $CURRENT_DIR
    echo "$GEN_JSON_BODY" >> json/$DEVICE.json
    exit 0
}

cloneError() {
    echo "Clone Failed!"
}

makeDefconfig() {
    MAKE_PARAMS="O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- \
                CROSS_COMPILE=aarch64-linux-android- \
                CROSS_COMPILE_ARM32=arm-linux-androideabi-"
    DEFCONFIG=$(echo $DEVICE'-perf_defconfig')
	if [[ -f arch/arm64/configs/$DEFCONFIG ]]; then
        make $MAKE_PARAMS $DEFCONFIG
    elif [[ -f arch/arm64/configs/vendor/$DEFCONFIG ]]; then
        make $MAKE_PARAMS vendor/$DEFCONFIG
	else
        DEFCONFIG=$(echo $DEVICE'_defconfig')
        if [[ -f arch/arm64/configs/$DEFCONFIG ]]; then
            make $MAKE_PARAMS $DEFCONFIG
        elif [[ -f arch/arm64/configs/vendor/$DEFCONFIG ]]; then
            make $MAKE_PARAMS vendor/$DEFCONFIG
        else
            echo "Defconfig not found"
        fi
    fi
}

makeKernel() {
    if [[ "$VERSION" == "3.18" ]]; then
        make -j$(nproc --all) $MAKE_PARAMS || buildFail
    fi
}

triggerBuild() {
    cloneCompiler
    echo "Starting Build"
    cd $BUILD_DIR
    START=$(date +"%s")
    makeDefconfig
    makeKernel
}

fetch-commit-id