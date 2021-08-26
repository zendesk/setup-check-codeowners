#!/bin/bash -ex
echo setup-check-codeowners: PWD=$PWD
echo setup-check-codeowners: PATH=$PATH
echo setup-check-codeowners: GITHUB_PATH=$GITHUB_PATH
grep -n ^ "$GITHUB_PATH" || :
echo "$PWD/bin" >> "$GITHUB_PATH"
