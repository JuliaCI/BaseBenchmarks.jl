#!/bin/bash
LAST_TAG=$(git describe --tags --abbrev=0)
git rev-list $1 ^$LAST_TAG | wc -l | sed -e 's/[^[:digit:]]//g'