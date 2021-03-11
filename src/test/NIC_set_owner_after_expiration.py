"""
    (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
"""

import tonos_ts4.ts4 as ts4
import sys
import os
import time
import unittest
from NIC_test_base import NICTest

sys.path.append(os.environ['TEST4_PATH'] + '/ts4_py_lib')

s2b = ts4.str2bytes
b2s = ts4.bytes2str

# Set a directory where the artifacts of the used contracts are located
ts4.set_tests_path(os.environ['OUT_PATH'] + '/')

# Toggle to print additional execution info
ts4.set_verbose(True)

class Test_owner_change_before_expiration(NICTest): 

    def test_owner_change_before_expiration(self): 
        (self.owner2_pk, self.owner2_pu) = ts4.make_keypair()

        self.owner2 = ts4.BaseContract('TestNICOwner', dict(), 
            nickname = 'owner2', pubkey = self.owner2_pu, private_key= self.owner2_pk)
        
        ts4.dispatch_messages()        
        self.set_now(self.owns_until + 10 )        
        
        # uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 value
        self.creator.call_method('setNextOwner', dict(nic_name_timespan = self.own_timespan, owner_key=self.owner2_pu, 
             owner_address = self.owner2.address()))

        ts4.dispatch_messages()

        # check owner changed
        self.assertEqual(int(self.owner2_pu, 16), self.nic_test_name.call_getter('m_name_owner_key'))
        self.assertEqual(self.owns_until + self.own_timespan, self.nic_test_name.call_getter('m_owns_until'))


if __name__ == '__main__':
    unittest.main()