#! /usr/bin/env zsh
#
# Current ssh configuration on my MAC:
# - arch
# - arch-remote
# - etele
# - etele-remote
# Package requirements:
# - wakeonlan
# - transmission-cli

alias wake-arch='ssh etele-router "ether-wake -i br0 3c:7c:3f:f5:33:cd"'
alias wake-arch-remote='ssh etele-router-remote "ether-wake -i br0 3c:7c:3f:f5:33:cd"'
alias wake-arch-lan='wakeonlan 3c:7c:3f:f5:33:cd'
