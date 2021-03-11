"""
    (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
"""

import tonos_ts4.ts4 as ts4
import sys
import os
import time
import unittest

from DeNSRoot_test_base import DeNSRootTest

sys.path.append(os.environ['TEST4_PATH'] + '/ts4_py_lib')

s2b = ts4.str2bytes
b2s = ts4.bytes2str

ton = ts4.GRAM
year_seconds = 31556926

# Set a directory where the artifacts of the used contracts are located
ts4.set_tests_path(os.environ['OUT_PATH'] + '/')

# Toggle to print additional execution info
ts4.set_verbose(True)

DAY_SEC = 24 * 60 * 60
YEAR_SEC = 31556926

class DeNSRoot_test_second_bidder_owns_test_name(DeNSRootTest): 

    def test_root_contract_created(self): 
        self.assertEqual(int(self.root_pu, 16), self.creator.call_getter('m_owner_pk'))

    def test_second_bidder_owns_test_name(self):        
        bid_seed = 54
        bid_value = 12 * ton
        (b2_pk, b2_pu) = ts4.make_keypair()

        bidder2 = ts4.BaseContract('TestAuctionBidder', dict(bid_key = b2_pu, seed = bid_seed), pubkey=b2_pu, private_key=b2_pk, nickname = 'bidder2')

        # Start name regsitration process
        # function regName(address dens, string name, uint32 nic_name_years, uint128 bid_value)
        bidder2.call_method('regName', dict(
            dens = self.creator.address(), 
            name = self.name, 
            nic_name_years = self.nic_years, 
            bid_value = bid_value))

        ts4.dispatch_messages()

        auction_addr = self.creator.call_getter('resolveAuctionAddress', dict(name = self.name))

        # auction collect phase
        self.inc_now(7 * DAY_SEC + 1)
        
        #  function payBid(uint256 bid_key, uint128 bid_value, uint32 seed
        bidder2.call_method('payBid', dict(auction = auction_addr, bid_value = 12 * ton))
        self.bidder.call_method('payBid', dict(auction = auction_addr, bid_value = 10 * ton))
        
        ts4.dispatch_messages()
        
        # after collect phase
        self.inc_now(DAY_SEC + 1 )

        bidder2.call_method('updateAuctionState', dict(auction = auction_addr))

        ts4.dispatch_messages()

        # get nic address
        nic_address = self.creator.call_getter('resolve', dict(name = self.name))

        nic_test_name = ts4.BaseContract('NIC', ctor_params= None, address= nic_address)

        # check second address is the winner
        self.assertEqual(int(b2_pu, 16), nic_test_name.call_getter('m_name_owner_key'))
        self.assertEqual(self.now + year_seconds, nic_test_name.call_getter('m_owns_until'))

        # check not winning bidder will receive bid funds back
        self.assertEqual(10 * ts4.GRAM, self.bidder.call_getter('m_last_received'))
        self.assertEqual(auction_addr, self.bidder.call_getter('m_last_from'))
    

if __name__ == '__main__':
    unittest.main()