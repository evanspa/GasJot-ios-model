#!/bin/bash

readonly projectName="iFuelPurchase-Core"
readonly version="$1"
readonly tagLabel="${projectName}-v${version}"

git tag -f -a $tagLabel -m 'version $version'
git push -f --tags
