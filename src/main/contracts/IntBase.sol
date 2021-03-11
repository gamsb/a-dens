// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "IntBaseLib.sol";


abstract contract IntBase {

    modifier onlyExtMessage {
        require( msg.sender == address(0), IntBaseErrors.NOT_AN_EXTERNAL_MESSAGE ); 
        _;
    }

    modifier onlyIntMessage {
        require( msg.sender != address(0), IntBaseErrors.NOT_AN_INTERNAL_MESSAGE );
        _;
    }

    modifier onlySigned {
        require( msg.pubkey() != 0, IntBaseErrors.EXTERNAL_MESSAGE_NOT_SIGNED ); 
        _;
    }

    modifier onlyValidSignature(uint256 key) {
        require( msg.pubkey() != 0, IntBaseErrors.EXTERNAL_MESSAGE_NOT_SIGNED ); 
        require( msg.pubkey() == key, IntBaseErrors.EXTERNAL_MESSAGE_INVALID_PUBKEY );
        _;
    }

    modifier onlyValidTvmSignature {
        require( msg.pubkey() != 0, IntBaseErrors.EXTERNAL_MESSAGE_NOT_SIGNED );
        require( msg.pubkey() == tvm.pubkey(), IntBaseErrors.EXTERNAL_MESSAGE_INVALID_TVM_PUBKEY );
        _;
    }

    function calculateBidHash(uint128 bid_value, uint32 seed) public pure returns (uint256) {
        TvmBuilder b;
        b.store(bid_value, seed);
        return tvm.hash(b.toCell());
    }

    function getAddress() public pure returns (address) {
        return address(this);
    }

    function _returnChange() internal pure {                                                                        
        msg.sender.transfer(0, false, 64);                            
    }

}
