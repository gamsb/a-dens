// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../main/contracts/NICLib.sol";
import "../../main/contracts/NIC.sol";
import "../../main/contracts/IDeNS.sol";

contract TestNICCreator is IDeNS {

    address public m_nic_address;
    uint256 public m_nic_hash;
    string public m_name;

    event OnNICCreated(string name, address nic_address, uint32 owns_until, uint256 name_owner_key, address name_owner_address);

    constructor () public {}

    function deployNic(string name, TvmCell nic_code, uint32 owns_until, uint256 name_owner_key, address name_owner_address) public {
        tvm.accept();
        uint256 h = tvm.hash(name); 
        TvmCell c = tvm.buildStateInit({
            code: nic_code,
            varInit: {
                m_name_hash: h,
                m_creator: address(this)
            },
            contr: NIC
        }); 

        NIC n = new NIC{
               wid: address(this).wid,
               value: 10 ton,
               stateInit: c
            }( name, owns_until, name_owner_key, name_owner_address);

        m_name = name;
        m_nic_hash = tvm.hash(c);
        m_nic_address = address(n);

        emit OnNICCreated(name,  m_nic_address, owns_until, name_owner_key, name_owner_address);
    }

    function updateState() external {
        tvm.accept();
        NIC(m_nic_address).updateState();
    }

    function setNextOwner(uint32 nic_name_timespan, uint256 owner_key, address owner_address) external {
        tvm.accept();
        NIC(m_nic_address).setNextOwner{value: 10 ton}(tvm.hash(m_name),  nic_name_timespan,  owner_key,  owner_address, 10 ton);
    }

    function stringHash(string s) public pure returns(uint256) {
        return tvm.hash(s);
    }
    
    function onNICPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk, uint32 valid_until) external override {
        // NOP
    }

    event OnNICNewOwner(string name, uint256 new_owner_key, address new_owner_address, uint32 owns_until,  uint32 owns_since,  uint256 old_owner_key, address old_owner_address);

    function onNICNewOwner(string name, uint256 new_owner_key, address new_owner_address, uint32 owns_until,  uint32 owns_since,  uint256 old_owner_key, address old_owner_address) external override {
        emit OnNICNewOwner(name, new_owner_key,  new_owner_address,  owns_until,   owns_since,   old_owner_key,  old_owner_address);
    }

    function onAuctionCompleted(string name, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_budget) external override {
        // NOP
    }
    function onAuctionFailed(string name, uint32 nic_name_timespan) external override {
        // NOP
    }

    function regName(string name, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk) external override {
        // NOP 
    }

    function regReservedName(string name,  uint32 nic_name_years, address name_owner, uint256 name_owner_key) external override {
        // NOP
    }

    event OnAuctionPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until, uint32 completed_at);

    function onAuctionPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until, uint32 completed_at) external override {
        emit OnAuctionPong(name_hash, nic_name_years, bid_hash, bid_key, reserved_until, completed_at);         
    }

}
