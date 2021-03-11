// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "IntBase.sol";
import "IntBaseLib.sol";
import "IAuction.sol";
import "AuctionLib.sol";
import "IDeNS.sol";

// name identity certificate sc
contract Auction is IntBase, IAuction {

    // registered nic name
    uint256 static public m_name_hash;
    // owner address
    address static public m_creator;

    // instance variables
    // current name owner 
    uint32 public m_nic_name_timespan;
    uint32 public m_nic_name_starts_at;
    uint32 public m_bid_phase_ends_at;
    uint32 public m_ends_at;
    string public m_name;
    uint32 public m_completed_at;

    // key - bidder public key, value - bid_hash
    mapping(uint256 => uint256) m_bids;
    // key - bidder public key
    mapping(uint256 => AuctionBidValue) m_payments;
    
    constructor(string name, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash) public onlyIntMessage onlyIfCreator {
        require( tvm.hash(name) == m_name_hash, AuctionErrors.AUCTION_INVALID_NAME_HASH );
        // check nic_name_timespan
        _init(name, nic_name_timespan, nic_name_starts_at, bid_phase_ends_at, ends_at/*, uint256 bid_key, uint256 bid_hash*/);
        _bid(bid_key, bid_hash);   
    }

    function _init(string name, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at /*, uint256 bid_key, uint256 bid_hash*/) private {
        require( tvm.hash(name) == m_name_hash, AuctionErrors.AUCTION_INVALID_NAME_HASH );
        // check nic_name_timespan
        require( nic_name_timespan > 0, AuctionErrors.AUCTION_ZERO_NIC_NAME_TIMESPAN );
        require( nic_name_starts_at > 0, AuctionErrors.AUCTION_ZERO_NIC_NAME_STARTS_AT );
        require( bid_phase_ends_at > 0, AuctionErrors.AUCTION_ZERO_BID_PHASE_ENDS_AT );
        require( ends_at > 0, AuctionErrors.AUCTION_ZERO_ENDS_AT );
        require( ends_at > bid_phase_ends_at, AuctionErrors.AUCTION_BID_PHASE_AFTER_AUCTION_END );
        m_name = name;
        m_nic_name_timespan = nic_name_timespan;
        m_nic_name_starts_at = nic_name_starts_at;
        m_bid_phase_ends_at = bid_phase_ends_at;
        m_ends_at = ends_at;
        mapping(uint256 => uint256) empty_bid;
        m_bids = empty_bid;        
        mapping(uint256 => AuctionBidValue) empty_payments;
        m_payments = empty_payments;
        m_completed_at = 0;
    }

    modifier onlyIfSameName(uint256 name_hash) {
        require( tvm.hash(m_name) == name_hash, AuctionErrors.AUCTION_INVALID_NAME_HASH );
        _;
    }

    modifier onlyIfCreator {
        // Check that the function was called by owner within the validity period
        require( msg.sender == m_creator, AuctionErrors.AUCTION_NOT_A_CREATOR );
        _;
    }

    modifier onlyValidBidPayValue(uint128 bid_value) {
        require( msg.value > IntBaseLib.MIN_NIC_BALANCE, AuctionErrors.AUCTION_NOT_ENOUGH_FUNDS_FOR_BID );
        require( msg.value >= bid_value, AuctionErrors.AUCTION_BID_PAY_NOT_ENOUGH_FUNDS_TRANSFERRED);
        _;
    }

    modifier onlyIfBidPhase {
        require( now <= m_bid_phase_ends_at,  AuctionErrors.AUCTION_NOT_WITHIN_BID_PHASE );
        _;
    }

    modifier onlyIfCollectPhase {
        require( m_bid_phase_ends_at < now && now <= m_ends_at,  AuctionErrors.AUCTION_NOT_WITHIN_COLLECT_PHASE );
        _;
    }

    function bid(uint256 bid_hash) external onlyExtMessage onlySigned onlyIfBidPhase {
        tvm.accept();
        _bid(msg.pubkey(),bid_hash);
    }

    function startNewAuctionRound(uint256 name_hash, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash) external override onlyIfCreator onlyIfSameName(name_hash) {
        _init(m_name, nic_name_timespan, nic_name_starts_at, bid_phase_ends_at, ends_at/*, uint256 bid_key, uint256 bid_hash*/);
        _bid(bid_key, bid_hash);
    }

    event OnAuctionPayBid(uint256 key, AuctionBidValue v);

    function payBid(uint256 bid_key, uint128 bid_value, uint32 seed) external onlyIntMessage onlyValidBidPayValue(bid_value) onlyIfCollectPhase {
        tvm.accept();
        // check if bid exists
        optional(uint256) h = m_bids.fetch(bid_key);
        if (h.hasValue()) {
            uint256 bh = calculateBidHash(bid_value, seed);
            if (h.get() == bh) {                
                if (!m_payments.exists(bid_key)) {
                    AuctionBidValue v = AuctionBidValue({
                        actual_value: msg.value,
                        bid_value: bid_value,
                        bid_address: msg.sender,
                        payed_at: now
                    });
                    m_payments.add(bid_key, v);
                    emit OnAuctionPayBid(bid_key, v);
                } else {
                    _returnChange();
                }
            } else {
                _returnChange();
            }
        } else {
            _returnChange();
        }
    }

    function getAuctionInfo() public view returns(AuctionInfo) {
        return AuctionInfo({
                nic_name: m_name, 
                nic_name_timespan: m_nic_name_timespan, 
                nic_name_starts_at: m_nic_name_starts_at, 

                bid_phase_ends_at: m_bid_phase_ends_at, 
                ends_at: m_ends_at,
                completed_at: m_completed_at,
                auction_state: getAuctionState() 
        });
    }
    
    function getAuctionState() public view returns (AuctionState) {
        AuctionState s = AuctionState.Completed;
        if ( m_completed_at == 0 ) {
            if ( now <= m_bid_phase_ends_at ) {
                s = AuctionState.Bidding;
            } else if (now <= m_ends_at) {
                s = AuctionState.Collecting;
            } else {
                s = AuctionState.Stopped;
            }
        }
        return s;
    }

    function ping(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until) external override onlyIfCreator onlyIfSameName(name_hash) {
        AuctionState s = getAuctionState();
        if (s == AuctionState.Bidding) {
            tvm.accept();
            _bid(bid_key, bid_hash);
            _returnChange();
        } else if (s == AuctionState.Stopped) {
            tvm.accept();
            _auctionEnd();
            _returnChange();
        } else if (s == AuctionState.Completed) {
            IDeNS(m_creator).onAuctionPong{value: 0, bounce:false, flag: 64}(name_hash, nic_name_years, bid_hash, bid_key, reserved_until, m_completed_at);
        }
    }

    function updateState() external override {
        tvm.accept();
        AuctionState s = getAuctionState();
        if (s == AuctionState.Stopped) {
            _auctionEnd();
        } 
        _returnChange();        
    }

    event OnAuctionBid(uint256 key, uint256 bid_hash);

    function _bid(uint256 key, uint256 bid_hash) private {
        if (key > 0 && bid_hash > 0) {
            if (m_bids.exists(key)) {            
                m_bids.replace(key, bid_hash);
            } else {
                m_bids.add(key, bid_hash);
            }
        }
        emit OnAuctionBid(key, bid_hash);
    }

    function _auctionEnd() private {
        if (m_payments.empty()) {
            // No payments collected
            IDeNS(m_creator).onAuctionFailed(m_name, m_nic_name_timespan);
        } else {
            AuctionBidValue first; 
            uint256 k_first = uint256(0); 
            AuctionBidValue second;
            uint256 k_second = uint256(0); 
            for((uint256 k, AuctionBidValue v) : m_payments) {
                if (k_first == uint256(0)) {
                    k_first = k; 
                    first = v;
                } else {
                    // check if first
                    if (v.bid_value > first.bid_value || ( v.bid_value == first.bid_value && v.payed_at < first.payed_at ) ) {
                        // check second set
                        if (k_second != uint256(0)) {
                            _returnBidValue(second.bid_address, second.actual_value);                            
                        }
                        k_second = k_first; 
                        second = first;
                        k_first = k;
                        first = v;
                    } else {
                        // check if second
                        if (k_second == uint256(0)) {
                            k_second = k; 
                            second = v; 
                        } else {
                            if (v.bid_value > second.bid_value || ( v.bid_value == second.bid_value && v.payed_at < second.payed_at ) ) {
                                _returnBidValue(second.bid_address, second.actual_value);
                                k_second = k; 
                                second = v;
                            } else {
                                _returnBidValue( v.bid_address, v.actual_value);
                            }
                        }
                    }
                }
            }
            // all payments except first and seconds returned to the bidder
            if (k_second != uint256(0)) {
                _returnBidValue(second.bid_address, second.actual_value);
                _returnBidValue(first.bid_address, first.actual_value - second.bid_value);
                // finish auction with second high price
                IDeNS(m_creator).onAuctionCompleted{value:second.bid_value, bounce: false}(m_name, m_nic_name_starts_at, m_nic_name_timespan, k_first, first.bid_address, second.bid_value);
            } else {
                // finish auction with only one bid
                IDeNS(m_creator).onAuctionCompleted{value:first.bid_value, bounce: false}(m_name, m_nic_name_starts_at , m_nic_name_timespan, k_first, first.bid_address, first.bid_value);
            }
        }
        m_completed_at = now;
        // destroy auction
        selfdestruct(m_creator);        
        //m_creator.transfer(0, false, 128);
    }

    event OnReturnBidValue(address bid_address, uint128 bid_value);
    function _returnBidValue(address bid_address, uint128 bid_value) private pure inline {
        emit OnReturnBidValue( bid_address, bid_value);
        address(bid_address).transfer(bid_value, false);
    }
    
}
