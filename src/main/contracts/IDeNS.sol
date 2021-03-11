// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

interface IDeNS {

    function regName(string name, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk) external;
    function regReservedName(string name,  uint32 nic_name_years, address name_owner, uint256 name_owner_key) external;
    function onAuctionPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until, uint32 completed_at) external;
    function onNICPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk, uint32 valid_until) external;
    function onNICNewOwner(string name, uint256 new_owner_key, address new_owner_address, uint32 owns_until,  uint32 owns_since,  uint256 old_owner_key, address old_owner_address) external;
    function onAuctionCompleted(string name, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_budget) external;
    function onAuctionFailed(string name, uint32 nic_name_timespan) external;

}