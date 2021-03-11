// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

enum AuctionState {
    Bidding, 
    Collecting, 
    Stopped, 
    Completed 
}

struct AuctionInfo {

    string nic_name;
    uint32 nic_name_timespan;
    uint32 nic_name_starts_at;

    uint32 bid_phase_ends_at;
    uint32 ends_at;
    uint32 completed_at;
    AuctionState auction_state;
}

struct AuctionBidValue {

    uint128 actual_value;    
    uint128 bid_value;
    address bid_address;
    uint32 payed_at;

}

library AuctionErrors {

    uint constant AUCTION_ZERO_NIC_NAME_TIMESPAN = 400;
    uint constant AUCTION_ZERO_NIC_NAME_STARTS_AT = 401;
    uint constant AUCTION_ZERO_BID_PHASE_ENDS_AT = 402;
    uint constant AUCTION_ZERO_ENDS_AT = 403;
    uint constant AUCTION_BID_PHASE_AFTER_AUCTION_END = 404;
    uint constant AUCTION_NOT_A_CREATOR = 405;
    uint constant AUCTION_NOT_ENOUGH_FUNDS_FOR_BID = 405;
    uint constant AUCTION_BID_PAY_NOT_ENOUGH_FUNDS_TRANSFERRED = 406;
    uint constant AUCTION_NOT_WITHIN_BID_PHASE = 407;
    uint constant AUCTION_NOT_WITHIN_COLLECT_PHASE = 408;
    uint constant AUCTION_INVALID_NAME_HASH = 409;

}
