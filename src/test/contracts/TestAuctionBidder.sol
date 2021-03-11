// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../main/contracts/IntBaseLib.sol";
import "../../main/contracts/IntBase.sol";
// import "../../main/contracts/NICLib.sol";
// import "../../main/contracts/NIC.sol";
import "../../main/contracts/IDeNS.sol";
import "../../main/contracts/INIC.sol";
import "../../main/contracts/Auction.sol";

contract TestAuctionBidder is IntBase  {

    uint256 public m_bid_key;
    uint32 public m_seed;

    uint128 public m_last_received;
    address public m_last_from;

    constructor (uint256 bid_key, uint32 seed) public {
        m_bid_key = bid_key; 
        m_seed = seed;
    }

    // function payBid(uint256 bid_key, uint128 bid_value, uint32 seed) external onlyIntMessage onlyValidBidPayValue(bid_value) onlyIfCollectPhase {
    function payBid(address auction, uint128 bid_value) public {
        tvm.accept();
        Auction(auction).payBid{value: bid_value, bounce: true}(m_bid_key, bid_value, m_seed);
    }

    function regName(address dens, string name, uint32 nic_name_years, uint128 bid_value) public {
        tvm.accept();        
        uint256 h = calculateBidHash(bid_value, m_seed);
        IDeNS(dens).regName{value: 1 ton, bounce: true}( name, nic_name_years, h, m_bid_key);
    }

    function updateAuctionState(address auction) public {
        tvm.accept();
        Auction(auction).updateState{value: 1 ton, bounce: true}();
    }

    function updateNICState(address nic) public {
        tvm.accept();
        INIC(nic).updateState{value: 1 ton, bounce: true}();
    }


    receive() external {
        m_last_received = msg.value;
        m_last_from = msg.sender;
    }

}
