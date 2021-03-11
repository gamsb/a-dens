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

# Set a directory where the artifacts of the used contracts are located
ts4.set_tests_path(os.environ['OUT_PATH'] + '/')

# Toggle to print additional execution info
ts4.set_verbose(True)

class NICTest(unittest.TestCase): 

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
        (cls.owner_pk, cls.owner_pu) = ts4.make_keypair()
        (cls.root_pk, cls.root_pu) = ts4.make_keypair()


        cls.set_now(int(time.time()))
        # 1 min
        cls.own_timespan = 60
        cls.owns_until = cls.now + cls.own_timespan
        cls.name = ts4.str2bytes('test_name')


        cls.owner = ts4.BaseContract('TestNICOwner', dict(), 
            nickname = 'owner', pubkey = cls.owner_pu, private_key= cls.owner_pk)

        ts4.ensure_address(cls.owner.address())

        # string name, TvmCell nic_code, uint32 owns_until, uint256 name_owner_key, address name_owner_address
        cls.nic_code = ts4.core.load_code_cell(os.environ['OUT_PATH'] + '/NIC.tvc')

        cls.creator = ts4.BaseContract('TestNICCreator', dict(), nickname = 'root', pubkey = cls.root_pu, private_key= cls.root_pk)

        # Dispatch unprocessed messages to actually construct a second contract
        cls.creator.call_method('deployNic', dict(name = cls.name , nic_code = cls.nic_code, owns_until = cls.owns_until, name_owner_key = cls.owner_pu, name_owner_address = cls.owner.address() ))

        cls.nic_addr = cls.creator.call_getter('m_nic_address') 
        ts4.register_nickname(cls.nic_addr, 'test_name_nic')

        cls.owner.call_method('set_nic_address', dict(nic_address = cls.nic_addr))

        print('Deploying test_name nic at {}'.format(cls.nic_addr))
        ts4.dispatch_messages()

        # print("hash('name') = ", cls.creator.call_getter("stringHash", {"s": s2b("name")}) )

        # At this point NIC_test_name is deployed at a known address,
        # so we create a wrapper to access it
        cls.nic_test_name = ts4.BaseContract('NIC', ctor_params = None, address = cls.nic_addr)

        
