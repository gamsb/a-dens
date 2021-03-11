// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "IntBase.sol";
import "IntBaseLib.sol";

import "IDeNS.sol";
import "DeNSRootLib.sol";

import "INIC.sol";
import "NIC.sol";

import "IAuction.sol";
import "Auction.sol";

// name identity certificate sc
contract DeNSRoot is IntBase, IDeNS {

    uint256 public m_owner_pk;

    // contract code cells
    TvmCell public m_auction_code;
    TvmCell public m_nic_code;

    // names reserver to m_reserved_names_owner
    mapping( uint256 => string ) m_reserved_names;
    address m_reserved_names_owner;
    mapping( uint256 => string ) m_names_cache;

    uint32 public m_auction_collect_phase_timespan = IntBaseLib.AUCTION_COLLECT_PHASE_TIMESPAN;

    constructor(TvmCell nic_code, TvmCell auction_code, address reserved_names_owner, string[] reserved_names) public onlySigned {
        // require( reserved_names_owner != address(0), DeNSRootErrors.DENS_CREATION_INVALID_OWNER_ADDRESS );
        logtvm('1');
        tvm.accept();
        m_owner_pk = msg.pubkey();
        // FIXME - check if valid code
        m_nic_code = nic_code;
        m_auction_code = auction_code; 
        if (reserved_names_owner != address(0)) {
            logtvm('1');
            m_reserved_names_owner = reserved_names_owner;
            logtvm('1');
            // build hash => name map
            for(string n : reserved_names) {
                m_reserved_names[tvm.hash(n)] = n;
            }
        }
    }
    
    modifier onlyNotReservedName(string name) {
        require( ! m_reserved_names.fetch(tvm.hash(name)).hasValue(), DeNSRootErrors.DENS_NAME_IS_RESERVED );
        _;
    }

    modifier onlyReservedName(string name) {
        require( m_reserved_names.fetch(tvm.hash(name)).hasValue(), DeNSRootErrors.DENS_NAME_IS_NOT_RESERVED );
        _;
    }

    modifier onlyIfOwner {
        // Check that the function was called by owner within the validity period
        require( msg.pubkey() == m_owner_pk,  DeNSRootErrors.DENS_ONY_OWNER );
        _;
    }

    modifier onlyValidNameYears(uint32 nic_name_years) {
        require( nic_name_years > 0, DeNSRootErrors.DENS_INVALID_NAME_YEARS );
        _;
    }

    function resolve(string name) public view returns (address) {
        return _resolve(tvm.hash(name));
    }

    function _resolve(uint256 name_hash) internal view returns (address) {
        TvmCell stateInit = _buildNICStateInit(name_hash);

        return address(tvm.hash(stateInit));
    }

    function regName(string name, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk) external override onlyNotReservedName(name) onlyValidNameYears(nic_name_years) {
        // function ping(string name, uint32 nic_name_timespan, uint256 bid_hash, address bid_address, uint256 bid_pk) external view;
        uint256 h = tvm.hash(name);
        optional(string) v = m_names_cache.fetch(tvm.hash(name));        
        if (!v.hasValue()) {
            m_names_cache[h] = name;
        }
        INIC(resolve(name)).ping{value: 0, bounce: true, flag: 64}(h, nic_name_years, bid_hash, bid_pk);
    }

    function regReservedName(string name,  uint32 nic_name_years, address name_owner, uint256 name_owner_key) external override onlyValidNameYears(nic_name_years) {
        require( m_reserved_names_owner != address(0), DeNSRootErrors.DENS_NO_RESERVED_NAME_OWNER ); 
        require( msg.sender == m_reserved_names_owner, DeNSRootErrors.DENS_NOT_RESERVED_NAME_OWNER );
        require( name_owner != address(0), DeNSRootErrors.DENS_EMPTY_RESERVED_NAME_OWNER_ADDRESS );
        require( name_owner_key != 0, DeNSRootErrors.DENS_EMPTY_RESERVED_NAME_OWNER_KEY );
        uint256 h = tvm.hash(name);
        require( m_reserved_names.fetch(h).hasValue(), DeNSRootErrors.DENS_NAME_IS_RESERVED);
        address a = resolve(name);
        uint32 nic_name_timespan = nic_name_years * IntBaseLib.SECONDS_IN_YEAR; 
        // setNextOwner(uint256 name_hash, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 value) external;
        INIC(a).setNextOwner{value: 0, bounce: true, flag: 64}(h, nic_name_timespan , name_owner_key, name_owner, msg.value);
        // event OnNICSetNewOwner(uint256 name_hash, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_value, address auction_address, uint128 msg_value, string name);
        emit OnNICSetNewOwner(h, 0, nic_name_timespan, name_owner_key,  name_owner, msg.value, address(0), msg.value, name);
    }

    function resolveAuctionAddress(string name) public view returns (address) {
        return _resolveAuctionAddress(tvm.hash(name));
    }

    function _resolveAuctionAddress(uint256 name_hash) public view returns (address) {
        TvmCell stateInit = _buildAuctionStateInit(name_hash);

        return address(tvm.hash(stateInit));
    }

    event OnNicCreation(string name, uint32 owns_until, uint256 owner_key, address owner_address);

    onBounce(TvmSlice slice) external {		
		// Start decoding the message. First 32 bits store the function id.
		uint32 functionId = slice.decode(uint32);

		if (functionId == tvm.functionId(INIC.ping)) {
            // no NIC name contract deployed
            uint256 name_hash;
            uint32 nic_name_years;
            uint256 bid_hash;
            uint256 bid_pk;
            // string name, uint32 nic_name_timespan, uint256 bid_hash, uint256 bid_pk
			(name_hash, nic_name_years, bid_hash, bid_pk) = slice.decodeFunctionParams(INIC.ping);
            require(nic_name_years > 0, DeNSRootErrors.DENS_INVALID_NAME_YEARS );
            _processNameRegistration(name_hash, nic_name_years, bid_hash, bid_pk, uint32(0));
		} else if (functionId == tvm.functionId(IAuction.ping) ) {
            // no auction found
            uint256 name_hash;
            uint32 nic_name_years; 
            uint256 bid_hash;
            uint256 bid_pk;
            uint32 reserved_until;
            // string name, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk, uint32 reserved_until
            (name_hash, nic_name_years, bid_hash, bid_pk, reserved_until) = slice.decodeFunctionParams(IAuction.ping);
            require(nic_name_years > 0, DeNSRootErrors.DENS_INVALID_NAME_YEARS );        
            _onAuctionPingBounced(name_hash, nic_name_years, bid_hash, bid_pk, reserved_until);
        } else if (functionId == tvm.functionId(INIC.setNextOwner)) {
            uint256 name_hash;
            uint32 nic_name_timespan;
            uint256 owner_key;
            address owner_address;
            uint128 value;
            // function setNextOwner(string name, uint32 nic_name_timespan, uint256 owner_key, address owner_address) external;
            (name_hash, nic_name_timespan, owner_key, owner_address, value) = slice.decodeFunctionParams(INIC.setNextOwner);
            // TODO min nic balance depends on name_timespan 
            require( value > IntBaseLib.MIN_NIC_BALANCE, DeNSRootErrors.DENS_NOT_ENOUGH_FUNDS_TO_CREATE_NIC );
            // create new NIC contract
            uint32 owns_until = now + nic_name_timespan;
            optional(string) n = m_names_cache.fetch(name_hash);
            if ( !n.hasValue() ) {
                n = m_reserved_names.fetch(name_hash);
            } 
            require ( n.hasValue() , DeNSRootErrors.DENS_NAME_CAN_NOT_RETRIEVE_BY_HASH );
            delete m_names_cache[name_hash];
            new NIC{
               wid: address(this).wid,
               value: value,
               stateInit: _buildNICStateInit(name_hash)
            }( n.get(), owns_until, owner_key, owner_address);
            emit OnNicCreation(n.get(), owns_until, owner_key, owner_address);
        }
	}

    event OnAuctionCompleted(string name, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_value, address auction_address);

    event OnNICSetNewOwner(uint256 name_hash, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_value, address auction_address, uint128 msg_value, string name);

    function onAuctionCompleted(string name, uint32 nic_name_starts_at, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 name_value) external override {
        require( msg.sender == resolveAuctionAddress(name), DeNSRootErrors.DENS_NOT_AN_AUCTION_SENDER );

        address a = resolve(name);
        emit OnAuctionCompleted( name, nic_name_starts_at, nic_name_timespan, owner_key, owner_address, name_value, a);
        uint256 h = tvm.hash(name);
        INIC(a).setNextOwner{value: 0, bounce: true, flag: 64}(h, nic_name_timespan, owner_key, owner_address, name_value);
        emit OnNICSetNewOwner(h, nic_name_starts_at, nic_name_timespan, owner_key, owner_address, name_value, a, msg.value, name);
    }

    event OnAuctionFailed(string name, uint32 nic_name_timespan); 

    function onAuctionFailed(string name, uint32 nic_name_timespan) external override {
        require( msg.sender == resolveAuctionAddress(name), DeNSRootErrors.DENS_NOT_AN_AUCTION_SENDER );
        emit OnAuctionFailed(name, nic_name_timespan);
        uint256 h = tvm.hash(name);
        optional(string) n = m_names_cache.fetch(h);

        if (n.hasValue()) {
            delete m_names_cache[h];
        }        
    }

    event OnNICNewOwner(string name, uint256 new_owner_key, address new_owner_address, uint32 owns_until,  uint32 owns_since, uint256 old_owner_key, address old_owner_address);

    function onNICNewOwner(string name, uint256 new_owner_key, address new_owner_address, uint32 owns_until,  uint32 owns_since, uint256 old_owner_key, address old_owner_address) external override {
        require( msg.sender == resolve(name), DeNSRootErrors.DENS_NOT_A_NIC_SENDER );
        emit OnNICNewOwner( name, new_owner_key, new_owner_address, owns_until, owns_since,  old_owner_key, old_owner_address);
    }

    function onNICPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk, uint32 valid_until) external override {
        require( msg.sender == _resolve(name_hash), DeNSRootErrors.DENS_NIC_PONG_NOT_A_NIC_ADDRESS);
        if ( valid_until > 0 ) {
            require( now + IntBaseLib.AUCTION_NOT_BEFORE_TIMESPAN >= valid_until, DeNSRootErrors.DENS_AUCTION_IS_NOT_ALLOWED_YET );
        }
        tvm.accept();

        _processNameRegistration(name_hash, nic_name_years, bid_hash, bid_pk, valid_until);
    }

    event OnNewAuctionRound(uint256 name_hash, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash, uint128 value);

    function onAuctionPong(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until, uint32 completed_at) external override {
        require( msg.sender == _resolveAuctionAddress(name_hash), DeNSRootErrors.DENS_NIC_PONG_NOT_AN_AUCTION_ADDRESS);
        require( now >= completed_at , DeNSRootErrors.DENS_NOT_VALID_AUCTION_COMPLETED_AT );
        if ( reserved_until > 0 ) {
            require( now + IntBaseLib.AUCTION_NOT_BEFORE_TIMESPAN >= reserved_until, DeNSRootErrors.DENS_AUCTION_IS_NOT_ALLOWED_YET );
        }
        tvm.accept();

        uint32 nic_name_timespan = nic_name_years * IntBaseLib.SECONDS_IN_YEAR;
        uint32 bid_phase_ends_at = now + calculateAuctionBidTimespan(nic_name_years);
        uint32 ends_at = bid_phase_ends_at + m_auction_collect_phase_timespan;
        uint32 nic_name_starts_at = math.max(ends_at, reserved_until);

        uint128 value = IntBaseLib.MIN_NIC_BALANCE + IntBaseLib.AUCTION_CONSTRUCTOR_FEE;
        IAuction(msg.sender).startNewAuctionRound{value: value}(name_hash, nic_name_timespan, nic_name_starts_at, bid_phase_ends_at, ends_at, bid_key, bid_hash);
            
        emit OnNewAuctionRound(name_hash, nic_name_timespan, nic_name_starts_at, bid_phase_ends_at, ends_at, bid_key, bid_hash, value);
    }

    event OnNewAuction(string name, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash); 

    function _onAuctionPingBounced(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_key, uint32 reserved_until) private inline {
        optional(string) n = m_names_cache.fetch(name_hash);
        require ( n.hasValue() , DeNSRootErrors.DENS_NAME_CAN_NOT_RETRIEVE_BY_HASH );  

        uint32 nic_name_timespan = nic_name_years * IntBaseLib.SECONDS_IN_YEAR;
        uint32 bid_phase_ends_at = now + calculateAuctionBidTimespan(nic_name_years);
        uint32 ends_at = bid_phase_ends_at + m_auction_collect_phase_timespan;
        uint32 nic_name_starts_at = ends_at;
        if ( reserved_until > 0 ) {
            require( ends_at >= reserved_until, DeNSRootErrors.DENS_AUCTION_IS_NOT_ALLOWED_YET );
        }
            
        new Auction{
               wid: address(this).wid,
               value: IntBaseLib.MIN_NIC_BALANCE + IntBaseLib.AUCTION_CONSTRUCTOR_FEE,
               stateInit: _buildAuctionStateInit(name_hash)
               // constructor(string name, uint32 nic_name_timespan, uint32 nic_name_starts_at, uint32 bid_phase_ends_at, uint32 ends_at, uint256 bid_key, uint256 bid_hash) public onlyIntMessage onlyIfCreator {
            }( n.get(), nic_name_timespan, nic_name_starts_at, bid_phase_ends_at, ends_at, bid_key, bid_hash);

        emit OnNewAuction(n.get(), nic_name_timespan, nic_name_starts_at, bid_phase_ends_at, ends_at, bid_key, bid_hash);
    }

    function _processNameRegistration(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk, uint32 reserved_until) private {
        address a = _resolveAuctionAddress(name_hash);
        IAuction(a).ping{value: 0, bounce: true, flag: 64}(name_hash, nic_name_years, bid_hash, bid_pk, reserved_until);
    }

    function calculateAuctionBidTimespan(uint32 nic_name_years) internal pure returns(uint32) {
        uint32 x = nic_name_years * IntBaseLib.REG_DAYS_PER_YER; 
        if ( x > IntBaseLib.AUCTION_MAX_DAYS ) {
            x = IntBaseLib.AUCTION_MAX_DAYS;
        }
        return x * 24 * 60 * 60;
    }

    function _buildAuctionStateInit(uint256 name_hash) private view returns (TvmCell) {
        return tvm.buildStateInit( {
            code: m_auction_code,
            varInit: {
                m_name_hash: name_hash,
                m_creator: address(this)
            },
            contr: Auction
        });
    }

    function _buildNICStateInit(uint256 name_hash) private view returns (TvmCell) {
        return tvm.buildStateInit( {
            code: m_nic_code,
            varInit: {
                m_name_hash: name_hash,
                m_creator: address(this)
            },
            contr: NIC
        });
    } 

}