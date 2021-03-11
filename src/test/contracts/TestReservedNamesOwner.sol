// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../main/contracts/IDeNS.sol";

contract TestReservedNamesOwner {

    address public m_dens_addr;

    constructor() public {
    }

    function set_m_dens_addr(address dens_addr) public {
        tvm.accept();
        m_dens_addr = dens_addr; 
    }

    function regReservedName(string name,  uint32 nic_name_years, address name_owner, uint256 name_owner_key) public view {
        tvm.accept();
        IDeNS(m_dens_addr).regReservedName{value: 10 ton, bounce: false}(name,  nic_name_years,  name_owner,  name_owner_key);
    }

}
