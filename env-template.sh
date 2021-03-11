#!/bin/bash

export SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

export DEBUG=no
export OUT_PATH=./target
export TEST4_PATH=./tonlabs/TestSuite4
export SOLC_PATH=./tonlabs/TON-Solidity-Compiler/build/solc
export SOLC_LIB_PATH=./tonlabs/TON-Solidity-Compiler/lib
export TVM_PATH=./tonlabs/TVM-linker/tvm_linker/target/release
export TONOS_CLI_PATH=./tonlabs/tonos-cli/tonos-cli-git/target/release
export PATH=$TONOS_CLI_PATH:$PATH

