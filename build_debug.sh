#!/bin/bash -eE

source ./env.sh

if [ "$DEBUG" = "yes" ]; then
    set -x
fi

compile() {
  echo "Compiling $1..."
  ${SOLC_PATH}/solc $1.sol --tvm-optimize --output-dir ${OUT_PATH}
  [[ $? -eq 0 ]] || { echo >&2 "Compilig $1 failed ..."; exit 1; }
  echo "Compiling $1...Ok"
}

link() {
  echo "Linking $1..."
  ${TVM_PATH}/tvm_linker compile ${OUT_PATH}/$1.code --abi-json ${OUT_PATH}/$1.abi.json --lib ${SOLC_LIB_PATH}/stdlib_sol.tvm -o ${OUT_PATH}/$1.tvc --debug-info
  [[ $? -eq 0 ]] || { echo >&2 "Linking $1 failed ..."; exit 1; }
  echo "Linking $1...Ok"
}

## build production

## compile "src/main/contracts/DeNSBase"
## link "DeNSBase"

compile "src/main/contracts/NIC"
link "NIC"

compile "src/main/contracts/DeNSRoot"
link "DeNSRoot"

compile "src/main/contracts/Auction"
link "Auction"

#compile "src/main/contracts/DeNSDebot"
#link "DeNSDebot"

## build tests

compile "src/test/contracts/TestNICCreator"
link "TestNICCreator"

compile "src/test/contracts/TestNICOwner"
link "TestNICOwner"

compile "src/test/contracts/TestAuctionCreator"
link "TestAuctionCreator"

compile "src/test/contracts/TestAuctionBidder"
link "TestAuctionBidder"

compile "src/test/contracts/TestReservedNamesOwner"
link "TestReservedNamesOwner"