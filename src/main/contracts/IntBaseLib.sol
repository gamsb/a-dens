// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

library IntBaseErrors {

    uint constant NOT_AN_EXTERNAL_MESSAGE = 101; 
    uint constant NOT_AN_INTERNAL_MESSAGE = 102; 
    uint constant EXTERNAL_MESSAGE_NOT_SIGNED = 103; 
    uint constant EXTERNAL_MESSAGE_INVALID_PUBKEY = 104; 
    uint constant EXTERNAL_MESSAGE_INVALID_TVM_PUBKEY = 105;

}

library IntBaseLib {
    // string hashes
    uint256 constant NAME_STRING_HASH = 82949781628683020043584167701092580744083967897129949097500759445395041316870;

    // time calculations
    uint32 constant NIC_MIN_OWNER_TIMESPAN_SEC = 24 * 60 * 60;
    uint32 constant SECONDS_IN_YEAR = 31556926;
    uint32 constant AUCTION_COLLECT_PHASE_TIMESPAN = 24 * 60 * 60;
    uint32 constant PING_TIMESPAN = 10;
    uint32 constant REG_DAYS_PER_YER = 7;
    uint32 constant AUCTION_MAX_DAYS = 28; 
    uint32 constant AUCTION_NOT_BEFORE_TIMESPAN = 28 * 24 * 60 * 60;

    // Fees and balances 
    uint128 constant MIN_BALANCE_RETURNED = 1 ton;
    uint128 constant MIN_NIC_BALANCE = 2 ton;
    uint128 constant NIC_CONSTRUCTOR_FEE = 0.1 ton;
    uint128 constant AUCTION_CONSTRUCTOR_FEE = 0.1 ton;

}