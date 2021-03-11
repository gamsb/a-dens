"""
    (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
"""

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

class AuctionTest_one_participant(AuctionTest): 

    def test_one_participant(self):        
        # collect phase
        self.inc_now(self.nic_name_timespan - 39)
        
        #  payBid(address auction, uint128 bid_value) public
        self.bidder.call_method('payBid', dict(auction = self.addr, bid_value = 10 * ts4.GRAM))
        self.inc_now(1)
        ts4.dispatch_messages()
        
        # after collect phase
        self.inc_now(40)

        self.auction.call_method('updateState', dict())

        ts4.dispatch_messages()

        # check only bidder is the the winner
        self.assertEqual(10 * ts4.GRAM, self.creator.call_getter('m_win_price'))
        self.assertEqual(self.bidder.address(), self.creator.call_getter('m_win_address'))
        self.assertEqual(int(self.bid_pu, 16), self.creator.call_getter('m_win_key'))

    

if __name__ == '__main__':
    unittest.main()