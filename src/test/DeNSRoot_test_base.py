"""
    (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
"""

import tonos_ts4.ts4 as ts4
import sys
import os
import time
import unittest

sys.path.append(os.environ['TEST4_PATH'] + '/ts4_py_lib')

s2b = ts4.str2bytes
b2s = ts4.bytes2str
ton = ts4.GRAM

# Set a directory where the artifacts of the used contracts are located
ts4.set_tests_path(os.environ['OUT_PATH'] + '/')

# Toggle to print additional execution info

class DeNSRootTest(unittest.TestCase): 

    @classmethod
    def inc_now(cls, s): 
        cls.set_now(cls.now + s)

    @classmethod
    def set_now(cls, now_time): 
        print("now = ", now_time)
        cls.now = now_time; 
        ts4.core.set_now(now_time)

    @classmethod
    def setUpClass(cls): 
        (cls.root_pk, cls.root_pu) = ts4.make_keypair()

        cls.set_now(int(time.time()))
        # 1 min
        cls.name_str = 'test_name'
        cls.name = ts4.str2bytes(cls.name_str)
        cls.nic_years = 1

        # string name, TvmCell nic_code, uint32 owns_until, uint256 name_owner_key, address name_owner_address
        cls.auction_code = ts4.core.load_code_cell(os.environ['OUT_PATH'] + '/Auction.tvc')
        cls.nic_code = ts4.core.load_code_cell(os.environ['OUT_PATH'] + '/NIC.tvc')
        
        (cls.r_owner_pk, cls.r_owner_pu) = ts4.make_keypair()

        cls.r_owner = ts4.BaseContract('TestReservedNamesOwner', dict(), nickname = 'r_owner', pubkey = cls.r_owner_pu, private_key= cls.r_owner_pk)
        cls.r_name_1 = 'reserved_name_1'
        cls.r_name_2 = 'reserved_name_2'

        # constructor(TvmCell nic_code, TvmCell auction_code, address reserved_names_owner, string[] reserved_names) public {
        cls.creator = ts4.BaseContract('DeNSRoot', dict(
            nic_code = cls.nic_code, 
            auction_code = cls.auction_code,
            # no reserved names used
            reserved_names_owner = cls.r_owner.address(), 
            reserved_names = [s2b(cls.r_name_1),s2b(cls.r_name_1)]
            ), nickname = 'root', pubkey = cls.root_pu, private_key= cls.root_pk)

        cls.r_owner.call_method('set_m_dens_addr', dict(dens_addr = cls.creator.address()))

        ts4.dispatch_messages()
        
        # after 10 sec
        cls.inc_now(10)

        # first bidder
        bid_seed = 34
        bid_value = 10 * ton

        (bid_pk, cls.bid_pu) = ts4.make_keypair()

        cls.bidder = ts4.BaseContract('TestAuctionBidder', dict(bid_key = cls.bid_pu, seed = bid_seed), pubkey=cls.bid_pu, private_key=bid_pk, nickname = 'bidder')

        # Start name regsitration process
        # function regName(address dens, string name. uint32 nic_name_years, uint128 bid_value) public
        cls.bidder.call_method('regName', dict(
            dens = cls.creator.address(),
            name = cls.name, 
            nic_name_years = cls.nic_years, 
            bid_value = bid_value))

        ts4.dispatch_messages()