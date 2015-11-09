#!/bin/bash

readonly PROJECT_NAME="Gas Jot Model"
readonly SDK_VERSION="9.1"
readonly ARCH="i386"
export LC_CTYPE=en_US.UTF-8

xcodebuild \
    -workspace "${PROJECT_NAME}.xcworkspace" \
    -scheme "PEFuelPurchase-ModelTests" \
    -configuration Debug \
    -sdk iphonesimulator${SDK_VERSION} \
    -arch ${ARCH} test
