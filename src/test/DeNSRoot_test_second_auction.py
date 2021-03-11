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
        print("1. first auction second bid")
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
        auction = ts4.BaseContract('Auction', ctor_params = None, address = auction_addr)

        print(auction.call_getter('getAuctionInfo'))

        # auction collect phase
        self.inc_now(7 * DAY_SEC + 1)
        
        #  function payBid(uint256 bid_key, uint128 bid_value, uint32 seed
        print("2. first auction bidder2 pays auction price 12")
        bidder2.call_method('payBid', dict(auction = auction_addr, bid_value = bid_value))

        print("3. first auction bidder1 pays auction price 10")
        self.bidder.call_method('payBid', dict(auction = auction_addr, bid_value = 10 * ton ))
        
        ts4.dispatch_messages()
        
        # after collect phase
        self.inc_now(DAY_SEC + 1 )

        print("4. first auction bidder2 updates auction")
        bidder2.call_method('updateAuctionState', dict(auction = auction_addr))
        # auction in completed state at this point

        ts4.dispatch_messages()

        self.inc_now(10)
        
        # get nic for test_name
        nic_address = self.creator.call_getter('resolve', dict(name = self.name))
        nic_test_name = ts4.BaseContract('NIC', ctor_params= None, address= nic_address)

        owns_until = nic_test_name.call_getter('m_owns_until')
        print("5. first auction bidder2 owns name for ", owns_until )
        
        bid3_seed = 34
        bid3_value = 22 * ton
        (b3_pk, b3_pu) = ts4.make_keypair()

        self.set_now(owns_until - (28 * DAY_SEC) - 2 )
        
        bidder3 = ts4.BaseContract('TestAuctionBidder', dict(bid_key = b3_pu, seed = bid3_seed), pubkey=b3_pu, private_key=b3_pk, nickname = 'bidder3')

        print("6. auction bidder3 will try to register name")

        # should cause 312 error by message dispatching
        with self.assertRaises(Exception):
            bidder3.call_method('regName', dict(
            dens = self.creator.address(), 
            name = self.name, 
            nic_name_years = self.nic_years, 
            bid_value = bid_value))        

            ts4.dispatch_messages()

        print(auction.call_getter('getAuctionInfo'))

        self.set_now(owns_until - (28 * DAY_SEC))

        print("7. name registration opened")

        print("8. bidder2 will try to register name")
        
        bidder2.call_method('regName', dict(
            dens = self.creator.address(), 
            name = self.name, 
            nic_name_years = self.nic_years, 
            bid_value = bid_value))

        print(auction.call_getter('getAuctionInfo'))

        ts4.dispatch_messages()

        # shift to the auction collect phase
        self.inc_now(7 * DAY_SEC + 1)

        print("9. bidder3 will try to pay for name")
        bidder3.call_method('payBid', dict(auction = auction_addr, bid_value = bid3_value))

        print("10. bidder2 will try to pay for name")
        bidder2.call_method('payBid', dict(auction = auction_addr, bid_value = 12 * ton))
        
        ts4.dispatch_messages()

        print("11. shift auction to the after collect")
        self.inc_now(DAY_SEC + 1 )

        print("12. first auction bidder2 updates auction")

        bidder2.call_method('updateAuctionState', dict(auction = auction_addr))
        # auction in completed state at this point

        ts4.dispatch_messages()

        print("13. move to the new owner NIC period")

        self.set_now(owns_until + 1)

        # update nic state
        bidder2.call_method('updateNICState', dict(nic = nic_address))
        ts4.dispatch_messages()

        # check second address is the winner
        self.assertEqual(int(b2_pu, 16), nic_test_name.call_getter('m_name_owner_key'))
        self.assertEqual(owns_until + year_seconds, nic_test_name.call_getter('m_owns_until'))
    

if __name__ == '__main__':
    unittest.main()