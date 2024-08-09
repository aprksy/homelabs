#! /bin/bash

# set commonfiles for vscode server dir
COMMON_FILES=~/commonfiles/vscode-server/

# get current vscode commit id
COMMIT_ID=$(code -v | head -2 | tail -1)

# download corresponding vscode server from github
wget https://update.code.visualstudio.com/commit:$COMMIT_ID/server-linux-x64/stable -P $COMMON_FILES
