#!/usr/bin/env bash

#
# Taken from 
# https://github.com/actions/runner-images/issues/2840#issuecomment-790492173
#

set -ux

df -h
sudo rm -rf /usr/share/dotnet
sudo rm -rf /opt/ghc
sudo rm -rf "/usr/local/share/boost"
sudo rm -rf "$AGENT_TOOLSDIRECTORY"
df -h
