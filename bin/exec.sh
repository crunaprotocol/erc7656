#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

if [[ "$3" == "" ]]; then
  npm run clean
  npm run compile
fi

npx hardhat run scripts/$1.js --network $2

