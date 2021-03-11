// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

library NICErrors {

    uint constant NIC_CREATION_INVALID_OWNS_UNTIL = 200;
    uint constant NIC_CREATION_MISSING_OWNER_ADDRESS = 201;
    uint constant NIC_NOT_A_CREATOR = 202;
    uint constant NIC_CAN_NOT_CHANGE_FIXED_NAME = 203;
    uint constant NIC_OWNER_EXPIRED = 204;
    uint constant NIC_OWNER_KEY_IS_EMPTY = 205;
    uint constant NIC_NOT_AN_OWNER_PUB_KEY = 206;
    uint constant NIC_OWNER_ADDRESS_IS_EMPTY = 207;
    uint constant NIC_NOT_AN_OWNER_ADDRESS = 208;
    uint constant NIC_CREATION_INVALID_NAME_HASH = 209;
    uint constant NIC_SET_NEXT_OWNER_INVALID_NAME_HASH = 210;

}
