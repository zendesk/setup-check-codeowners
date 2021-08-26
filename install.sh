#!/bin/bash -ex
install -d -m 755 "$HOME/bin/"
install -m 755 "$GITHUB_ACTION_PATH/bin/check-codeowners" "$HOME/bin/"
echo "$HOME/bin" >> "$GITHUB_PATH"
