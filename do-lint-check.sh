#!/bin/bash

readonly PROJECT_NAME="iFuelPurchase-Core"
readonly IOS_SIMULATOR_SDK="iphonesimulator7.1"
readonly CONFIGURATION="Debug"
readonly ARCHITECTURE="i386" # 32-bit iPhone/iPad simulator

oclint-runner.sh ${PROJECT_NAME}.xcodeproj ${PROJECT_NAME} ${IOS_SIMULATOR_SDK} ${CONFIGURATION} ${ARCHITECTURE}
