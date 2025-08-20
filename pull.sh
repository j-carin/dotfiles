#!/bin/bash
if ! git diff-index --quiet HEAD --; then
    read -p "You have uncommitted changes. Continue? (y/N) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi
git fetch origin
git reset --hard origin/main
./ln.sh