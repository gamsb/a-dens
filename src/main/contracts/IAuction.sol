// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

interface IAuction {

    function ping(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk, uint32 reserved_until) external;
    function startNewAuctionRound(uint256 name_hash, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash) external;
    function updateState() external; 

}