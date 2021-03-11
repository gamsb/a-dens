// (c) 2021. Gamsb <gamsb@gmx.de>, gpg fingerprint: 02421F6A9B1BFE61013BB959196A6EC746D69660
pragma ton-solidity >= 0.35.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "NICLib.sol";
import "IntBase.sol";
import "IntBaseLib.sol";
import "INIC.sol";
import "IDeNS.sol";

struct NextOwner {
    uint32 owns_until;
    uint256 owner_key; 
    address owner_address;
    uint128 balance;
}

// name identity certificate sc
contract NIC is IntBase, INIC {

    // registered nic name
    uint256 static public m_name_hash;
    // owner address
    address static public m_creator;

    // instance variables
    // current name owner 
    uint256 public m_name_owner_key;
    address public m_name_owner_address;
    uint32 public m_owns_until;
    string public m_name;
    address public m_dens_root;
    
    mapping(string => string) m_param_strings;
    mapping(string => address) m_addresses;

    // contract to manage sub-names registration
    TvmCell m_root_code;
    NextOwner m_next_owner; 

    constructor(string name, uint32 owns_until, uint256 name_owner_key, address name_owner_address) public onlyIntMessage onlyIfCreator {
        require( tvm.hash(name) == m_name_hash, NICErrors.NIC_CREATION_INVALID_NAME_HASH );
        // check owner key
        require( owns_until >= now, NICErrors.NIC_CREATION_INVALID_OWNS_UNTIL );
        if ( name_owner_key == 0 ) {
            require( name_owner_address != address(0), NICErrors.NIC_CREATION_MISSING_OWNER_ADDRESS );
        }
        m_name = name;
        m_owns_until = owns_until;
        m_name_owner_key = name_owner_key;
        m_name_owner_address = name_owner_address;
    }

    modifier onlyIfCreator {
        // Check that the function was called by owner within the validity period
        require( msg.sender == m_creator, NICErrors.NIC_NOT_A_CREATOR );
        _;
    }

    modifier notReservedString(string nic_name) {
        // name
        require( IntBaseLib.NAME_STRING_HASH != tvm.hash(nic_name), NICErrors.NIC_CAN_NOT_CHANGE_FIXED_NAME );
        _;
    }

    modifier onlyIfNameOwnerNotExpired {
        require( now < m_owns_until, NICErrors.NIC_OWNER_EXPIRED );
        if (msg.sender == address(0)) {            
            // ext msg
            require( m_name_owner_key != 0, NICErrors.NIC_OWNER_KEY_IS_EMPTY );
            require( msg.pubkey() == m_name_owner_key, NICErrors.NIC_NOT_AN_OWNER_PUB_KEY );
        } else {
            // int msg
            require( m_name_owner_address != address(0), NICErrors.NIC_OWNER_ADDRESS_IS_EMPTY );
            require( msg.sender == m_name_owner_address, NICErrors.NIC_NOT_AN_OWNER_ADDRESS );
        }
        _;
    }

    function getNICString(string nic_name) public view returns (string) {
        if ( IntBaseLib.NAME_STRING_HASH == tvm.hash(nic_name) ) {
            return m_name;  
        }
        return m_param_strings[nic_name];
    }

    function setNICString(string nic_name, string value) public notReservedString(nic_name) onlyIfNameOwnerNotExpired {
        tvm.accept();
        if ( m_param_strings.exists(nic_name) ) {
            m_param_strings.replace(nic_name, value);
        } else {
            m_param_strings.add(nic_name, value);
        }
    }

    function setNICDeNSRoot(address dens_root) public onlyIfNameOwnerNotExpired {
        tvm.accept();
        m_dens_root = dens_root;
    }


    function removeNICString(string nic_name) public notReservedString(nic_name)  onlyIfNameOwnerNotExpired {
        tvm.accept();
        if ( m_param_strings.exists(nic_name) ) {
            delete m_param_strings[nic_name];
        }
    }

    function getWhois() external override view returns(Whois) {
        Whois w = Whois({
            name: m_name, 
            nicAddress: address(this), 
            nicDeNSRoot: m_dens_root,
            ownerAddress: m_name_owner_address, 
            ownerPublicKey: m_name_owner_key,
            validUntil: m_owns_until
        });
        return w;
    }

    function ping(uint256 name_hash, uint32 nic_name_years, uint256 bid_hash, uint256 bid_pk) external view override onlyIfCreator {
        IDeNS(msg.sender).onNICPong{bounce: false, flag: 64}(name_hash, nic_name_years, bid_hash, bid_pk, m_owns_until);
    }

    function updateState() external override {        
        tvm.accept();
        _updateOwner();
        _returnChange();
    }

    function setNextOwner(uint256 name_hash, uint32 nic_name_timespan, uint256 owner_key, address owner_address, uint128 value) external override onlyIfCreator {
        require( name_hash == tvm.hash(m_name), NICErrors.NIC_SET_NEXT_OWNER_INVALID_NAME_HASH );
        tvm.accept();
        m_next_owner = NextOwner({
                owns_until: m_owns_until + nic_name_timespan, 
                owner_key: owner_key,
                owner_address: owner_address, 
                balance: msg.value
            });
        _updateOwner();
    }

    function _updateOwner() private {
        if (now >= m_owns_until) {
            if (m_next_owner.owns_until != 0) {
                _changeOwner(); 
            }
        }
    }

    function _changeOwner() private {
        if (address(this).balance > m_next_owner.balance) {
            uint128 return_balance = address(this).balance - m_next_owner.balance;

            if (return_balance >= IntBaseLib.MIN_BALANCE_RETURNED) {
                if (m_name_owner_address == address(0)) {
                    address(m_creator).transfer(return_balance, false);
                } else {
                    address(m_name_owner_address).transfer(return_balance, true);
                }
            }
        }

        IDeNS(m_creator).onNICNewOwner(m_name, m_next_owner.owner_key,  m_next_owner.owner_address, m_next_owner.owns_until, m_owns_until, m_name_owner_key, m_name_owner_address);

        m_name_owner_key = m_next_owner.owner_key;
        m_name_owner_address = m_next_owner.owner_address;
        m_owns_until = m_next_owner.owns_until;

        NextOwner eowner;
        m_next_owner = eowner; 

        mapping(string => string) pempty;
        m_param_strings = pempty;
        
        mapping(string => address) aempty; 
        m_addresses = aempty;

        TvmCell tempty;
        m_root_code = tempty;
    }

}
