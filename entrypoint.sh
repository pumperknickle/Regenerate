#!/bin/sh -l

swift test
echo "Hello $1"
time=$(date)
echo ::set-output name=time::$time
