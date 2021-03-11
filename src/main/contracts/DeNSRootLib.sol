// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

library DeNSRootErrors {

    uint constant DENS_CREATION_MISSING_PUBKEY = 300;
    uint constant DENS_ONY_OWNER = 301;
    uint constant DENS_CREATION_INVALID_MESSAGE_KEY = 302;
    uint constant DENS_CREATION_INVALID_OWNER_ADDRESS = 303;
    uint constant DENS_NAME_IS_RESERVED = 304;
    uint constant DENS_NAME_IS_NOT_RESERVED = 305;
    uint constant DENS_INVALID_NAME_YEARS = 306;
    uint constant DENS_NOT_ENOUGH_FUNDS_TO_CREATE_NIC = 307;
    uint constant DENS_NOT_AN_AUCTION_SENDER = 308;
    uint constant DENS_NOT_A_NIC_SENDER = 309;
    uint constant DENS_NIC_PONG_NOT_A_NIC_ADDRESS = 310;
    uint constant DENS_NAME_CAN_NOT_RETRIEVE_BY_HASH = 311;    
    uint constant DENS_AUCTION_IS_NOT_ALLOWED_YET = 312;
    uint constant DENS_NIC_PONG_NOT_AN_AUCTION_ADDRESS = 313;
    uint constant DENS_NOT_VALID_AUCTION_COMPLETED_AT = 314;
    uint constant DENS_NO_RESERVED_NAME_OWNER = 315; 
    uint constant DENS_NOT_RESERVED_NAME_OWNER = 316; 
    uint constant DENS_EMPTY_RESERVED_NAME_OWNER_ADDRESS = 317; 
    uint constant DENS_EMPTY_RESERVED_NAME_OWNER_KEY = 318; 

}
