// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./Asset.sol";
import "../interfaces/IAssetIssuerState.sol";

// ------------ upgradeable contract

contract Handler is Initializable, Asset {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    address private serverPubKey;
    IAssetIssuerState IState;

    function initalizeAddr(IAssetIssuerState _IState)
        internal
        onlyInitializing
    {
        IState = _IState;
    }

    function setWhitelisted(address[] calldata _users, bool _isWhitelisted)
        external
        onlyRole(ADMIN)
    {
        _setWhitelisted(_users, _isWhitelisted);
    }

    function createAsset(
        uint256 _assetId,
        uint256 _tokenCap,
        IERC20Upgradeable _revToken
    ) external onlyRole(ADMIN) {
        _createAsset(_assetId, _tokenCap, _revToken);
    }

    function updateAssetCap(uint256 _assetId, uint256 _tokenCap)
        external
        onlyRole(ADMIN)
    {
        _updateAssetTokenCap(_assetId, _tokenCap);
    }

    function mintAsset(uint256 _assetId, uint256 _amount)
        external
        onlyRole(ADMIN)
    {
        _mintAsset(_assetId, _amount, address(this));
    }

    function claimUnits(
        uint256[] calldata _tokenIds,
        bytes memory _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        bytes memory message = abi.encode(msg.sender, address(this), _tokenIds);
        require(
            ecrecover(
                keccak256(abi.encodePacked(_prefix, message)),
                _v,
                _r,
                _s
            ) == serverPubKey,
            "Invalid signature"
        );

        uint256 assetId = _getTokenAsset(_tokenIds[0]);
        uint256 totalClaim = totalShareRev[assetId];
        _setClaimed(assetId, _tokenIds, totalClaim);
        _claimUnits(address(this), msg.sender, _tokenIds);
    }

    function returnUnits(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external onlyRole(ADMIN) {
        _claimUnits(_from, _to, _tokenIds);
    }

    function addRevenue(
        uint256 _assetId,
        uint256 _totalRev,
        uint256 _unitsCount,
        uint256 _amountPerShare
    ) external onlyRole(ADMIN) {
        require(
            _totalRev / _unitsCount == _amountPerShare,
            "Invalid input data"
        );
        _addRevenue(msg.sender, _assetId, _totalRev, _amountPerShare);
    }

    function claimRevenue(uint256 _assetId, uint256[] calldata _tokenIds)
        external
    {
        _claimRevenue(msg.sender, _assetId, _tokenIds);
    }

    function updateServer(address _serverPubKey) external onlyRole(ADMIN) {
        serverPubKey = _serverPubKey;
    }

    function setTransfersPaused(bool _paused) external onlyRole(ADMIN) {
        _setTransfersPaused(_paused);
    }

    function setAssetTransfersPaused(uint256 _assetId, bool _paused)
        external
        onlyRole(ADMIN)
    {
        _setAssetTransfersPaused(_assetId, _paused);
    }
    // ----- NEED TO FIX PAUSABLE ----

    // function pauseHandler() external onlyRole(ADMIN) {
    //     _pause();
    // }

    // function unpauseHandler() external onlyRole(ADMIN) {
    //     _unpause();
    // }
}
