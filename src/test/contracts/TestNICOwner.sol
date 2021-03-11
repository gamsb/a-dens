// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../main/contracts/NICLib.sol";
import "../../main/contracts/NIC.sol";
import "../../main/contracts/IDeNS.sol";

contract TestNICOwner {

    address public m_nic_address;

    constructor() public {
    }

    function set_nic_address(address nic_address) public {
        tvm.accept();
        m_nic_address = nic_address; 
    }
    
    function setNICString(string nic_name, string value) public view {
        tvm.accept();
        NIC(m_nic_address).setNICString(nic_name, value);
    }

}
