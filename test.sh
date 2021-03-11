#!/bin/bash

source ./env.sh

if [ "$DEBUG" = "yes" ]; then
    set -x
fi

test() {
  echo "testing $1..."
  python3 $1
  [[ $? -eq 0 ]] || { echo >&2 "Test $1 failed ..."; exit 1; }
}

test "src/test/NIC_test.py"
test "src/test/NIC_set_owner_at_expiration.py"
test "src/test/NIC_set_owner_before_expiration.py"
test "src/test/NIC_set_owner_after_expiration.py"
test "src/test/Auction_test_second_bidder_wins_auction_with_12.py"
test "src/test/Auction_test_with_three_bidders.py"
test "src/test/Auction_test_earlier_bid_pay_wins.py"
test "src/test/Auction_test_one_participant.py"
test "src/test/Auction_test_without_pays_will_fail.py"
test "src/test/DeNSRoot_test_second_bidder_owns_test_name.py"
test "src/test/DeNSRoot_test_second_auction.py"
test "src/test/DeNSRoot_test_reserved_name.py"