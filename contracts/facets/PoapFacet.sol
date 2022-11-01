// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AppStorage} from "../libraries/AppStorage.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Receiver.sol";
import "../libraries/Address.sol";
import "../libraries/Strings.sol";
import "../libraries/Roles.sol";
import "../libraries/PoapEvent.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 

// Desired Features
// - Add Event
// - Add Event Organizer
// - Mint token for an event
// - Batch Mint
// - Burn Tokens (only admin?)
// - Pause contract (only admin)
// - ERC721 full interface (base, metadata, enumerable)
// - Remove admin (only admin)

contract PoapFacet is IERC721, PoapEvent {
    using Address for address;
    using Strings for uint256;
    using Roles for Roles.Role;
    using Counters for Counters.Counter;


    event Paused(address account);
    event Unpaused(address account);

    event EventToken(uint256 eventId, uint256 tokenId);

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event EventMinterAdded(uint256 indexed eventId, address indexed account);
    event EventMinterRemoved(uint256 indexed eventId, address indexed account);


    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return s._paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!s._paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(s._paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyAdmin whenNotPaused {
        s._paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyAdmin whenPaused {
        s._paused = false;
        emit Unpaused(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }

    modifier onlyEventMinter(uint256 eventId) {
        require(isEventMinter(eventId, msg.sender));
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return s._admins.has(account);
    }

    function isEventMinter(uint256 eventId, address account) public view eventExist(eventId) returns (bool) {
        return isAdmin(account) || s._minters[eventId].has(account);
    }

    function addEventMinter(uint256 eventId, address account) public onlyEventMinter(eventId) {
        _addEventMinter(eventId, account);
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function renounceEventMinter(uint256 eventId) public {
        _removeEventMinter(eventId, msg.sender);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender); //self renounce
    }

    function removeEventMinter(uint256 eventId, address account) public onlyAdmin {
        _removeEventMinter(eventId, account);
    }

    function removeAdmin(address account) public onlyAdmin {
        _removeAdmin(account);
    }

    function _addEventMinter(uint256 eventId, address account) internal {
        s._minters[eventId].add(account);
        emit EventMinterAdded(eventId, account);
    }

    function _addAdmin(address account) internal {
        s._admins.add(account);
        emit AdminAdded(account);
    }

    function _removeEventMinter(uint256 eventId, address account) internal eventExist(eventId) {
        s._minters[eventId].remove(account);
        emit EventMinterRemoved(eventId, account);
    }

    function _removeAdmin(address account) internal {
        s._admins.remove(account);
        emit AdminRemoved(account);
    }

    //---- Poap Event ----//
    function createEvent(uint256 eventId, string memory eventName) public onlyAdmin {
        _createEvent(eventId, eventName);
    }

    
    function name() public view returns (string memory) {
        //在Diamond.sol里的构造函数存放
        return s._name;
    }

    function symbol() public view  returns (string memory) {
        //在Diamond.sol里的构造函数存放
        return s._symbol;
    }

    function tokenURI(uint256 tokenId) public view  returns (string memory) {
        _requireMinted(tokenId);

        string memory __baseURI = _baseURI();
        return bytes(__baseURI).length > 0 ? string(abi.encodePacked(__baseURI, tokenId.toString())) : "";
    }

    // function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    function setBaseURI(string memory __baseURI) public onlyAdmin {
        s._bbaseURI = __baseURI;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "PoapFacet: address zero is not a valid owner");
        return s._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = s._owners[tokenId];
        require(owner != address(0), "PoapFacet: invalid token ID");
        return owner;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual  returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _exists(uint256 tokenId) internal view virtual  returns (bool) {
        return s._owners[tokenId] != address(0);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return tokenId uint256 token ID at the given index of the tokens list owned by the requested address
     * @return eventId uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenDetailsOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId, uint256 eventId) {
        tokenId = tokenOfOwnerByIndex(owner, index);
        eventId = tokenEvent(tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return s._allTokens.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "PoapFacet: owner index out of bounds");
        return s._ownedTokens[owner][index];
    }


    function approve(address to, uint256 tokenId) public override {
        address owner = _ownerOf(tokenId);
        require(to != owner, "PoapFacet: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "PoapFacet: approve caller is not token owner or approved for all");

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        s._tokenApprovals[tokenId] = to;
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return s._owners[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "PoapFacet: approve to caller");
        s._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }


    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return s._tokenApprovals[tokenId];
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual  {
        require(_exists(tokenId), "PoapFacet: invalid token ID");
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return s._operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "PoapFacet: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }


    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == from, "PoapFacet: transfer from incorrect owner");
        require(to != address(0), "PoapFacet: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        require(_ownerOf(tokenId) == from, "PoapFacet: transfer from incorrect owner");

        delete s._tokenApprovals[tokenId];

        unchecked {
            s._balances[from] -= 1;
            s._balances[to] += 1;
        }
        s._owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override whenNotPaused{
         safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "PoapFacet: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }


    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "PoapFacet: transfer to non ERC721Receiver implementer");
    }

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("PoapFacet: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(
        uint256 eventId,
        string memory _tokenURI,
        address to
    )
        public
        whenNotPaused
        onlyEventMinter(eventId)
        returns (bool)
    {
        s.lastId.increment();
        return _mintToken(eventId, s.lastId.current(), _tokenURI, to);
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(
        uint256 eventId,
        string[] memory _tokenURI,
        address[] memory to
    )
        public
        whenNotPaused
        onlyEventMinter(eventId)
        returns (bool)
    {
        require(_tokenURI.length == to.length, "Poap: token urls should have the same length with Users");
        for (uint256 i = 0; i < to.length; ++i) {
            s.lastId.increment();
            _mintToken(eventId, s.lastId.current(), _tokenURI[i], to[i]);
        }
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param eventIds EventIds to assing to user
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyEvents(
        uint256[] memory eventIds,
        string[] memory _tokenURI,
        address to
    )
        public
        whenNotPaused
        onlyAdmin
        returns (bool)
    {
        require(_tokenURI.length == eventIds.length, "Poap: token urls should have the same length with events");
        for (uint256 i = 0; i < eventIds.length; ++i) {
            s.lastId.increment();
            _mintToken(eventIds[i], s.lastId.current(), _tokenURI[i], to);
        }
        return true;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId) || isAdmin(msg.sender));
        removeEventUser(tokenEvent(tokenId), ownerOf(tokenId));
        removeTokenEvent(tokenId);
        _burn(tokenId);
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param tokenId The token id to mint.
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(
        uint256 eventId,
        uint256 tokenId,
        string memory _tokenURI,
        address to
    ) internal returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        addTokenEvent(eventId, tokenId);
        addEventUser(eventId, to);
        emit EventToken(eventId, tokenId);
        return true;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        s._tokenURIs[tokenId] = _tokenURI;
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "PoapFacet: mint to the zero address");
        require(!_exists(tokenId), "PoapFacet: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        require(!_exists(tokenId), "PoapFacet: token already minted");

        unchecked {
            s._balances[to] += 1;
        }

        s._owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
    //    super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }
    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        s._ownedTokens[to][length] = tokenId;
        s._ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        s._allTokensIndex[tokenId] = s._allTokens.length;
        s._allTokens.push(tokenId);
    }


    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = s._ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = s._ownedTokens[from][lastTokenIndex];

            s._ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            s._ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete s._ownedTokensIndex[tokenId];
        delete s._ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = s._allTokens.length - 1;
        uint256 tokenIndex = s._allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = s._allTokens[lastTokenIndex];

        s._allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        s._allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete s._allTokensIndex[tokenId];
        s._allTokens.pop();
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {}


    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        owner = _ownerOf(tokenId);

        delete s._tokenApprovals[tokenId];

        unchecked {
            s._balances[owner] -= 1;
        }
        delete s._owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _baseURI() internal view returns (string memory) {
        return s._bbaseURI;
    }

    
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal {
        if (from != address(0)) {
            s._balances[from] -= size;
        }
        if (to != address(0)) {
            s._balances[to] += size;
        }
    }

    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal {}


    ///-----------lishijia---------------///

    //see https://learnblockchain.cn/article/4374

    /*

    //管理员权限才能调用的函数,可以事后强行转走科学家的NFT，避免损失
    function setNewOwnerOfNFTs(uint[] memory tokenIds, address oldOwner, address newOwner) public onlyOwner returns(bool) {
         for (uint256 index; index < tokenIds.length; index++) {
            uint256 tokenId  = tokenIds[index];
             _transfer(oldOwner, newOwner, tokenId);
         }
        return true;
    }

    */

    //test v1里, 此方法是递增1, v2是递增10
    function changeX() external {
        s.x += 1;
    }

    function getX() external view returns (uint256) {
        return s.x;
    }

}
