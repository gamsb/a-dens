"""
    (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
"""

'''
    test the NIC sc
'''

import tonos_ts4.ts4 as ts4
import sys
import os
import time
import unittest

sys.path.append(os.environ['TEST4_PATH'] + '/ts4_py_lib')

s2b = ts4.str2bytes
b2s = ts4.bytes2str

# Set a directory where the artifacts of the used contracts are located
ts4.set_tests_path(os.environ['OUT_PATH'] + '/')

# Toggle to print additional execution info

class AuctionTest(unittest.TestCase): 

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
        cls.nic_name_timespan = 100

        # string name, TvmCell nic_code, uint32 owns_until, uint256 name_owner_key, address name_owner_address
        cls.code = ts4.core.load_code_cell(os.environ['OUT_PATH'] + '/Auction.tvc')

        cls.creator = ts4.BaseContract('TestAuctionCreator', dict(), nickname = 'root', pubkey = cls.root_pu, private_key= cls.root_pk)

        bid_seed = 34
        bid_value = 10 * ts4.GRAM

        (bid_pk, cls.bid_pu) = ts4.make_keypair()

        cls.bidder = ts4.BaseContract('TestAuctionBidder', dict(bid_key = cls.bid_pu, seed = bid_seed), pubkey=cls.bid_pu, private_key=bid_pk)

        # Dispatch unprocessed messages to actually construct a second contract
        # function deployAuction(string name, TvmCell code, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash) public {
        cls.creator.call_method('deployAuction', dict(name = cls.name , code = cls.code,
          nic_name_timespan = cls.nic_name_timespan, 
          nic_name_starts_at = cls.now + cls.nic_name_timespan, bid_phase_ends_at = cls.now + cls.nic_name_timespan - 40 , 
          ends_at = cls.now + cls.nic_name_timespan, 
          bid_key = cls.bid_pu, bid_value = bid_value, bid_seed = bid_seed))

        cls.addr = cls.creator.call_getter('m_address') 
        ts4.ensure_address(cls.addr)
        ts4.register_nickname(cls.addr, 'auction')

        print('Deploying test_name auction at {}'.format(cls.addr))
        ts4.dispatch_messages()

        # At this point NIC_test_name is deployed at a known address,
        # so we create a wrapper to access it
        cls.auction = ts4.BaseContract('Auction', ctor_params = None, address = cls.addr)
