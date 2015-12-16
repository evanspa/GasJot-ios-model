#!/bin/bash

readonly PROJECT_NAME="Gas Jot Model"
readonly SDK_VERSION="9.2"
readonly ARCH="i386"
export LC_CTYPE=en_US.UTF-8

xcodebuild \
-workspace "${PROJECT_NAME}.xcworkspace" \
-scheme "Gas Jot ModelTests" \
-configuration Debug \
-sdk iphonesimulator${SDK_VERSION} \
-verbose \
-arch ${ARCH} test
