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

class DeNSRoot_test_reserved_name(DeNSRootTest): 

    def test_reserved_name(self):
        print("1. delegate reserved name 1")
        (r_owner_1_pk, r_owner_1_pu) = ts4.make_keypair()
        # can be also 
        r_owner_1 = ts4.BaseContract('TestReservedNamesOwner', dict(), pubkey=r_owner_1_pu, private_key=r_owner_1_pk, nickname = 'r_owner_1')

        # Start name regsitration process
        # function regName(address dens, string name, uint32 nic_name_years, uint128 bid_value)
        self.r_owner.call_method('regReservedName', dict(
            name = s2b(self.r_name_1),
            nic_name_years = 1,
            name_owner = r_owner_1.address(),
            name_owner_key = r_owner_1_pu))

        ts4.dispatch_messages()

        r_nic_addr = self.creator.call_getter('resolve', dict(name = s2b(self.r_name_1)))
        r_nic = ts4.BaseContract('NIC', ctor_params = None, address = r_nic_addr)

        # check second address is the winner
        self.assertEqual(int(r_owner_1_pu, 16), r_nic.call_getter('m_name_owner_key'))
        self.assertEqual(self.now + year_seconds, r_nic.call_getter('m_owns_until'))
    

if __name__ == '__main__':
    unittest.main()