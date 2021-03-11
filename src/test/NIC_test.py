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

class Test(NICTest): 
    
    def test_info_is_set(self): 
        self.assertEqual('test_name', b2s(self.nic_test_name.call_getter('m_name')))
        self.assertEqual(int(self.owner_pu, 16), self.nic_test_name.call_getter('m_name_owner_key'))
        self.assertEqual(self.owns_until, self.nic_test_name.call_getter('m_owns_until'))
        print(self.nic_test_name.call_getter('getWhois'))

    def test_owner_can_set_nic_string(self):
        self.nic_test_name.call_method('setNICString', dict(nic_name = s2b('ip'), value=s2b('1.1.1.1')), private_key=self.owner_pk)
        self.assertEqual('1.1.1.1', b2s(self.nic_test_name.call_getter('getNICString', dict(nic_name = s2b('ip')))))

    def test_not_owner_fails_to_set_nic_string(self):
        with self.assertRaises(Exception):
            self.nic_test_name.call_method('setNICString', dict(nic_name = s2b('ip'), value=s2b('1.1.1.2')))

    def test_owner_can_set_nic_string_using_owner_contract(self):
        self.owner.call_method('setNICString', dict(nic_name = s2b('ip'), value=s2b('1.1.1.2')))
        ts4.dispatch_messages()
        s = self.nic_test_name.call_getter('getNICString', dict(nic_name=s2b('ip')))
        self.assertEqual('1.1.1.2', b2s(s))

    def test_owner_fails_to_set_nic_string_if_expires(self): 
        self.inc_now(self.own_timespan)
        with self.assertRaises(Exception):
            self.nic_test_name.call_method('setNICString', dict(nic_name = s2b('ip'), value=s2b('1.1.1.1')), private_key=self.owner_pk)


if __name__ == '__main__':
    unittest.main()