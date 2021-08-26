#!/bin/bash -ex
install -d -m 755 ~/bin
install -m 755 ./bin/check-codeowners ~/bin/
echo "$HOME/bin" >> "$GITHUB_PATH"
