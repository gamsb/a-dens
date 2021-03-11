// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

struct Whois {
    // registered
    string name;
    address nicAddress;
    address nicDeNSRoot;
    address ownerAddress;
    uint256 ownerPublicKey;
    // expiration date
    uint32 validUntil;
} 

interface INIC {

    function ping(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk) external view;
    function setNextOwner(uint256 name_hash, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 value) external;
    function updateState() external; 
    function getWhois() external view returns(Whois);

}