#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

if [[ ! -d "flattened" ]]; then
  mkdir flattened
fi

NODE_ENV=test npx hardhat flatten contracts/$1.sol > flattened/$1-flattened.sol
#scripts/clean-licenses-in-flattened.js $1

