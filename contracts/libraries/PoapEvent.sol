// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Roles.sol";
import "./AppStorage.sol";

/**
 * @title PoapEvent
 * @dev Library for managing events and its users
 */
contract PoapEvent  {
    AppStorage internal s;


    // struct Event {
    //     string name;
    //     mapping(address => bool) reverse_index;
    // }

    event EventAdded(uint256 indexed eventId, string eventName);

    // mapping(uint256 => Event) private _event_infos;
    // mapping(uint256 => uint256) private _token_events;
    // mapping(uint256 => bool) private _event_exist;

    modifier eventExist(uint256 eventId) {
        require(s._event_exist[eventId], "Poap: event not exists");
        _;
    }

    modifier userNotExist(uint256 eventId, address user) {
        require(
            !s._event_infos[eventId].reverse_index[user],
            "Poap: already assigned the event"
        );
        _;
    }

    modifier tokenExist(uint256 token) {
        require(s._token_events[token] != uint256(0), "Poap: token wasn't exist");
        _;
    }

    // function __EVENT_init() public initializer {}

    function _createEvent(uint256 eventId, string memory eventName) internal {
        require(!s._event_exist[eventId], "Poap: event already existed");
        s._event_exist[eventId] = true;
        s._event_infos[eventId].name = eventName;
        emit EventAdded(eventId, eventName);
    }

    function addEventUser(uint256 eventId, address user)
        internal
        eventExist(eventId)
        userNotExist(eventId, user)
    {
        s._event_infos[eventId].reverse_index[user] = true;
    }

    function removeEventUser(uint256 eventId, address user)
        internal
        eventExist(eventId)
    {
        require(
            s._event_infos[eventId].reverse_index[user],
            "Poap: user didn't exist"
        );
        s._event_infos[eventId].reverse_index[user] = false;
    }

    function eventHasUser(uint256 eventId, address user)
        public
        view
        eventExist(eventId)
        returns (bool)
    {
        return s._event_infos[eventId].reverse_index[user];
    }

    function eventMetaName(uint256 eventId)
        public
        view
        eventExist(eventId)
        returns (string memory)
    {
        return s._event_infos[eventId].name;
    }

    function tokenEvent(uint256 token)
        public
        view
        tokenExist(token)
        returns (uint256)
    {
        return s._token_events[token];
    }

    function addTokenEvent(uint256 eventId, uint256 token)
        internal
        eventExist(eventId)
    {
        require(
            s._token_events[token] == uint256(0),
            "Poap: token already existed"
        );
        s._token_events[token] = eventId;
    }

    function removeTokenEvent(uint256 token) internal {
        s._token_events[token] = uint256(0);
    }

    // For future extensions
    uint256[50] private ______gap;
}
