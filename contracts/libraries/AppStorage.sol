// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Roles.sol";
// import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

struct Event {
    string name;
    mapping(address => bool) reverse_index;
}

//所有合约共用此存储区
struct AppStorage {
     // Token name
    string _name;

    // Token symbol
    string _symbol;

    // Base token URI
    string  _bbaseURI;

    //用于测试
    uint256 x;
    uint256 y;

    // Mapping from token ID to owner address
    mapping(uint256 => address) _owners;

    // Mapping owner address to token count
    mapping(address => uint256) _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address)  _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) _ownedTokens;
    
   // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256)  _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[]  _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256)  _allTokensIndex;

    mapping(uint256 => Event)  _event_infos;
    mapping(uint256 => uint256)  _token_events;
    mapping(uint256 => bool)  _event_exist;

    Roles.Role  _admins;
    mapping(uint256 => Roles.Role)  _minters;

    // Last Used id (used to generate new ids)
    Counters.Counter lastId;

    mapping(uint256 => string) _tokenURIs;

    bool  _paused;


}