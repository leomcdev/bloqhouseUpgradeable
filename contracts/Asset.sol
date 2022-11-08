// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/ICNR.sol";

contract Asset is
    Initializable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    /**
     * @notice Called first in the initialize (RWAT) contract upon deployment. Functions with
     * state variables that are not stated as CONSTANTS are required to be declared with
     * the onlyInitalizing statement, to not interrupt the initialize call in the RWAT contract.
     */

    function initializeCNR(ICNR _CNR) internal onlyInitializing {
        CNR = _CNR;
    }

    ICNR private CNR;
    mapping(address => bool) public isWhitelisted;

    bool pausedTransfers;
    mapping(uint256 => bool) public assetPaused;

    mapping(uint256 => uint256) public nextId;
    mapping(uint256 => uint256) public lastId;

    mapping(uint256 => IERC20Upgradeable) public assetRevToken;
    mapping(uint256 => uint256) public totalShareRev;
    mapping(uint256 => uint256) public claimedRev;

    address serverPubKey;
    string name_;
    string symbol_;

    /**
     * @notice Creates the asset with a token cap.
     * @dev 9 zeros are added.
     */
    function _createAsset(
        uint256 _assetId,
        uint256 _tokenCap,
        IERC20Upgradeable _revToken
    ) internal {
        require(nextId[_assetId] == 0, "Asset already exists");
        assetRevToken[_assetId] = _revToken;
        nextId[_assetId] = _assetId * 1_000_000_000;
        lastId[_assetId] = _assetId * 1_000_000_000 + _tokenCap;
    }

    /**
     * @notice Updates asset cap.
     */
    function _updateAssetTokenCap(uint256 _assetId, uint256 _tokenCap)
        internal
    {
        require(
            nextId[_assetId] <= _assetId * 1_000_000_000 + _tokenCap,
            "Asset cap can not be lower than minted amount"
        );
        lastId[_assetId] = _assetId * 1_000_000_000 + _tokenCap;
    }

    /**
     * @notice Mints assets with respective ID as long as the max amount
     * of minted assets has not been exceeded.
     */
    function _mintAsset(
        uint256 _assetId,
        uint256 _amount,
        address _to
    ) internal {
        require(
            (nextId[_assetId] + _amount) <= lastId[_assetId],
            "Amount exceeds max"
        );
        for (uint256 i = 0; i < _amount; i++) {
            _mint(_to, nextId[_assetId]);
            nextId[_assetId]++;
        }
    }

    /**
     * @notice Whitelists multiple users to be available for shares.
     * @dev Also deWhitelists users by setting to false.
     */
    function _setWhitelisted(address[] calldata _users, bool _whitelisted)
        internal
    {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length; i++) {
            isWhitelisted[_users[i]] = _whitelisted;
        }
    }

    /**
     * @notice User claim units.
     */
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

    /**
     * @notice Set units to claimed.
     */
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

    /**
     * @dev Add revenue into contract to later be added to the respecive assets.
     */
    function _addRevenue(
        address _from,
        uint256 _assetId,
        uint256 _totalRev,
        uint256 _amountPerToken
    ) internal {
        totalShareRev[_assetId] += _amountPerToken;
        assetRevToken[_assetId].transferFrom(_from, address(this), _totalRev);
    }

    /**
     * @notice Calculates the revenue that each investor can claim.
     * @dev Adds the new value into claimed rev and transfers the revenue to the owner.
     */
    function _claimRevenue(
        address _owner,
        uint256 _assetId,
        uint256[] calldata _tokenIds
    ) internal {
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

    function _setTransfersPaused(bool _paused) internal {
        pausedTransfers = _paused;
    }

    function _setAssetTransfersPaused(uint256 _assetId, bool _paused) internal {
        assetPaused[_assetId] = _paused;
    }

    function _updateServer(address _serverPubKey) internal {
        serverPubKey = _serverPubKey;
    }

    /**
     * @notice Overrides the _beforeTokenTransfer in the ERC721Upgradeable contract
     * @dev Checks state and that users are whitelisted.
     */
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
