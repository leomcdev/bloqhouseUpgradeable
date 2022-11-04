// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/ICNR.sol";

// ------------ upgradeable contract

// execution contract
contract Asset is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    // needs to be initialized or disabled
    // function initializeAsset() internal onlyInitializing {
    //     __ERC721_init("name", "symbol");
    //     // CNR?
    // }

    bytes32 public constant HANDLER = keccak256("HANDLER");

    ICNR private CNR;
    mapping(address => bool) public isWhitelisted;

    bool pausedTransfers;
    mapping(uint256 => bool) public assetPaused;

    mapping(uint256 => uint256) public nextId;
    mapping(uint256 => uint256) public lastId;

    mapping(uint256 => IERC20Upgradeable) public assetRevToken;
    mapping(uint256 => uint256) public totalShareRev;
    mapping(uint256 => uint256) public claimedRev;

    function _createAsset(
        uint256 _assetId,
        uint256 _tokenCap,
        IERC20Upgradeable _revToken
    ) internal onlyRole(DEFAULT_ADMIN_ROLE) {
        require(nextId[_assetId] == 0, "Asset already exists");
        assetRevToken[_assetId] = _revToken;
        nextId[_assetId] = _assetId * 1_000_000_000;
        lastId[_assetId] = _assetId * 1_000_000_000 + _tokenCap;
    }

    function _updateAssetTokenCap(uint256 _assetId, uint256 _tokenCap)
        internal
        onlyRole(HANDLER)
    {
        require(
            nextId[_assetId] <= _assetId * 1_000_000_000 + _tokenCap,
            "Asset cap can not be lower than minted amount"
        );
        lastId[_assetId] = _assetId * 1_000_000_000 + _tokenCap;
    }

    function _mintAsset(
        uint256 _assetId,
        uint256 _amount,
        address _to
    ) internal onlyRole(HANDLER) {
        require(
            (nextId[_assetId] + _amount) <= lastId[_assetId],
            "Amount exceeds max"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to, nextId[_assetId]);
            nextId[_assetId]++;
        }
    }

    function _setWhitelisted(address[] calldata _users, bool _whitelisted)
        internal
        onlyRole(HANDLER)
    {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length; i++) {
            isWhitelisted[_users[i]] = _whitelisted;
        }
    }

    // removed onlyrole handler...
    function _claimUnits(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) internal {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _transfer(_from, _to, _tokenIds[i]);
        }
    }

    // removed onlyrole handler...
    function _setClaimed(
        uint256 _assetId,
        uint256[] calldata _tokenIds,
        uint256 _amount
    ) internal {
        uint256 length = _tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            require(
                _getTokenAsset(_tokenIds[i]) == _assetId,
                "Invalid token for asset"
            );
            claimedRev[_tokenIds[i]] = _amount;
        }
    }

    function _addRevenue(
        address _from,
        uint256 _assetId,
        uint256 _totalRev,
        uint256 _amountPerToken
    ) internal onlyRole(HANDLER) {
        totalShareRev[_assetId] += _amountPerToken;
        assetRevToken[_assetId].transferFrom(_from, address(this), _totalRev);
    }

    function _claimRevenue(
        address _owner,
        uint256 _assetId,
        uint256[] calldata _tokenIds
    ) internal onlyRole(HANDLER) {
        require(isWhitelisted[_owner], "Owner is not whitelisted");
        uint256 totalToGet;
        uint256 length = _tokenIds.length;
        uint256 totalAssetRev = totalShareRev[_assetId];
        for (uint256 i = 0; i < length; i++) {
            require(ownerOf(_tokenIds[i]) == _owner, "Invalid token owner");
            require(
                _getTokenAsset(_tokenIds[i]) == _assetId,
                "Invalid token for asset"
            );
            totalToGet += totalAssetRev - claimedRev[_tokenIds[i]];
            claimedRev[_tokenIds[i]] = totalAssetRev;
        }
        assetRevToken[_assetId].transferFrom(address(this), _owner, totalToGet);
    }

    function _setTransfersPaused(bool _paused) internal onlyRole(HANDLER) {
        pausedTransfers = _paused;
    }

    function _setAssetTransfersPaused(uint256 _assetId, bool _paused)
        internal
        onlyRole(HANDLER)
    {
        assetPaused[_assetId] = _paused;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (!(from == address(0) || from == address(this))) {
            require(!pausedTransfers, "Transfers are currently paused");
            require(!assetPaused[_getTokenAsset(tokenId)], "Asset is paused");
            require(
                isWhitelisted[from] && isWhitelisted[to],
                "Invalid token transfer"
            );
        }
    }

    function _getTokenAsset(uint256 _tokenId) public pure returns (uint256) {
        return _tokenId / 1_000_000_000;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return ICNR(CNR).getNFTURI(address(this), _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __gap;
}
