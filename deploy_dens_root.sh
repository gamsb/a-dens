#!/bin/bash -eE

set -x

source ./env.sh

set -e
tonoscli=${TONOS_CLI_PATH}/tonos-cli
tvmlinker=${TVM_PATH}/tvm_linker 
debot=DeNSRoot
debot_abi=./target/$debot.abi.json
debot_tvc=./target/$debot.tvc
debot_keys=./$debot.keys.json
giver=0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94
target_address=0:0000000000000000000000000000000000000000000000000000000000000000

function giver {
    $tonoscli call --abi ./data/nse-giver.abi.json $giver sendGrams "{\"dest\":\"$1\",\"amount\":100000000000}"
}

function get_address {
echo $(cat log.log | grep "Raw address:" | cut -d ' ' -f 3)    
}

function get_code_str {    
    ${TVM_PATH}/tvm_linker decode --tvc $1 | grep '^ code:' | cut -d ' ' -f 3
}

$tonoscli config --url http://0.0.0.0

echo getaddr
$tonoscli genaddr $debot_tvc $debot_abi --genkey $debot_keys > log.log
debot_address=$(get_address)
echo address = $debot_address
echo get some tons 
giver $debot_address

echo deploy
nic_code=$(cat ./target/NIC.tvc | base64 -w 0 )
auction_code=$(cat ./target/Auction.tvc | base64 -w 0 )
reserved_names_owner=0:0000000000000000000000000000000000000000000000000000000000000000
reserved_names=[]
$tonoscli deploy $debot_tvc "{\"nic_code\":\"$nic_code\",\"auction_code\":\"$auction_code\",\"reserved_names_owner\":\"$reserved_names_owner\",\"reserved_names\":$reserved_names}" --sign $debot_keys --abi $debot_abi

# echo done
echo $debot_address > address.log
