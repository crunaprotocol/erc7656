#!/usr/bin/env bash

root_dir=$(dirname $(realpath $(dirname "$0")))
# if not run from the root, we cd into the root
cd $root_dir

NODE_ENV=test npx hardhat verify --network $1 0x7656f0fB4Ca6973cf99D910B36705a2dEDA97eA1
