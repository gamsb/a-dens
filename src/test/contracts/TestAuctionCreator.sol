// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../main/contracts/IntBaseLib.sol";
import "../../main/contracts/IntBase.sol";
// import "../../main/contracts/NICLib.sol";
// import "../../main/contracts/NIC.sol";
import "../../main/contracts/IDeNS.sol";
import "../../main/contracts/Auction.sol";

contract TestAuctionCreator is IDeNS, IntBase  {

    address public m_address;
    uint256 public m_hash;
    string public m_name;

    uint256 public m_win_key;
    address public m_win_address; 
    uint128 public m_win_price;

    string public m_failed_name; 

    event OnAuctionCreated(string name, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash);

    constructor () public {}

    // uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash
    function deployAuction(string name, TvmCell code, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint128 bid_value, uint32 bid_seed) public {
        tvm.accept();
        uint256 h = tvm.hash(name);
        TvmCell c = tvm.buildStateInit({
            code: code,
            varInit: {
                m_name_hash: h,
                m_creator: address(this)
            },
            contr: Auction
        }); 

        uint256 bid_hash = calculateBidHash(bid_value, bid_seed);

        Auction n = new Auction{
               wid: address(this).wid,
               value: 10 ton,
               stateInit: c
            }( name, nic_name_timespan, nic_name_starts_at,  bid_phase_ends_at,  ends_at,  bid_key, bid_hash);

        m_name = name;
        m_hash = tvm.hash(c);
        m_address = address(n);        

        emit OnAuctionCreated(name,  nic_name_timespan, nic_name_starts_at,  bid_phase_ends_at,  ends_at,  bid_key, bid_hash);
    }

    
    function onNICPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk, uint32 valid_until) external override {
        // NOP
    }

    function onNICNewOwner(string name, uint256 new_owner_key, address new_owner_address, uint32 owns_until,  uint32 owns_since,  uint256 old_owner_key, address old_owner_address) external override {
        // NOP
    }

    event OnAuctionCompleted(string name, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_budget);

    function onAuctionCompleted(string name, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_budget) external override {
        m_win_address = owner_address; 
        m_win_price = name_budget;
        m_win_key = owner_key;

        emit OnAuctionCompleted( name, nic_name_starts_at, nic_name_timespan,  owner_key,  owner_address,  name_budget);
    }

    event OnAuctionFailed(string name, uint32 nic_name_timespan);

    function onAuctionFailed(string name, uint32 nic_name_timespan) external override {
        m_win_address = address(0); 
        m_win_price = uint128(0);
        m_win_key = uint256(0);

        m_failed_name = name; 
        
        emit OnAuctionFailed( name, nic_name_timespan);
    }

    event OnAuctionPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until, uint32 completed_at);

    function onAuctionPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until, uint32 completed_at) external override {
        emit OnAuctionPong(name_hash, nic_name_years, bid_hash, bid_key, reserved_until, completed_at);         
    }

    function regName(string name, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk) external override {
        // NOP 
    }

    function regReservedName(string name,  uint32 nic_name_years, address name_owner, uint256 name_owner_key) external override {
        // NOP
    }


}
