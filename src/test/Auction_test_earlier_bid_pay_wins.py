"""
    (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
"""

'''
    test the auction sc
'''

import tonos_ts4.ts4 as ts4
import sys
import os
import time
import unittest

from Auction_test_base import AuctionTest

sys.path.append(os.environ['TEST4_PATH'] + '/ts4_py_lib')

s2b = ts4.str2bytes
b2s = ts4.bytes2str

# Set a directory where the artifacts of the used contracts are located
ts4.set_tests_path(os.environ['OUT_PATH'] + '/')

# Toggle to print additional execution info
ts4.set_verbose(True)

class AuctionTest_earlier_bid_wins(AuctionTest): 

    def test_earlier_bid_wins(self):        
        seed2 = 54
        (b2_pk, b2_pu) = ts4.make_keypair()

        bidder2 = ts4.BaseContract('TestAuctionBidder', dict(bid_key = b2_pu, seed = seed2), pubkey=b2_pu, private_key=b2_pk)

        seed3 = 42
        (b3_pk, b3_pu) = ts4.make_keypair()

        bidder3 = ts4.BaseContract('TestAuctionBidder', dict(bid_key = b3_pu, seed = seed3), pubkey=b3_pu, private_key=b3_pk)

        # function bid(uint256 bid_hash) external onlyExtMessage onlySigned onlyIfBidPhase {
        self.auction.call_method('bid', dict(bid_hash = hex(self.auction.call_getter('calculateBidHash', dict(bid_value = 12 * ts4.GRAM, seed = 54)))),private_key = b2_pk)

        ts4.dispatch_messages()

        # collect phase
        self.inc_now(self.nic_name_timespan - 39)
        
        #  payBid(address auction, uint128 bid_value) public
        bidder2.call_method('payBid', dict(auction = self.addr, bid_value = 12 * ts4.GRAM))

        self.inc_now(1)
        ts4.dispatch_messages()
        
        bidder3.call_method('payBid', dict(auction = self.addr, bid_value = 12 * ts4.GRAM))        
        self.inc_now(1)
        ts4.dispatch_messages()

        self.bidder.call_method('payBid', dict(auction = self.addr, bid_value = 10 * ts4.GRAM))
        self.inc_now(1)
        ts4.dispatch_messages()
        
        # after collect phase
        self.inc_now(40)

        self.auction.call_method('updateState', dict())

        ts4.dispatch_messages()

        # check second address is the winner
        self.assertEqual(10 * ts4.GRAM, self.creator.call_getter('m_win_price'))
        self.assertEqual(bidder2.address(), self.creator.call_getter('m_win_address'))
        self.assertEqual(int(b2_pu, 16), self.creator.call_getter('m_win_key'))

        # check not winning bidder will receive bid funds back
        self.assertEqual(10 * ts4.GRAM, self.bidder.call_getter('m_last_received'))
        self.assertEqual(self.auction.address(), self.bidder.call_getter('m_last_from'))
        
        self.assertEqual(12 * ts4.GRAM, bidder3.call_getter('m_last_received'))
        self.assertEqual(self.auction.address(), bidder3.call_getter('m_last_from'))
    

if __name__ == '__main__':
    unittest.main()