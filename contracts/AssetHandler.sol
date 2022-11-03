// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAssetIssuerState.sol";

contract AssetHandler is AccessControl, Pausable {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    IAssetIssuerState public issuerState;
    address private serverPubKey;

    constructor(IAssetIssuerState _issuerState, address _default_admin) {
        issuerState = _issuerState;
        _grantRole(DEFAULT_ADMIN_ROLE, _default_admin);
    }

    function setWhitelisted(address[] calldata _users, bool _isWhitelisted)
        external
        onlyRole(ADMIN)
    {
        issuerState.setWhitelisted(_users, _isWhitelisted);
    }

    function createAsset(
        uint256 _assetId,
        uint256 _tokenCap,
        IERC20 _revToken
    ) external onlyRole(ADMIN) {
        issuerState.createAsset(_assetId, _tokenCap, _revToken);
    }

    function updateAssetCap(uint256 _assetId, uint256 _tokenCap)
        external
        onlyRole(ADMIN)
    {
        issuerState.updateAssetTokenCap(_assetId, _tokenCap);
    }

    function mintAsset(uint256 _assetId, uint256 _amount)
        external
        onlyRole(ADMIN)
    {
        issuerState.mintAsset(_assetId, _amount, address(issuerState));
    }

    function claimUnits(
        uint256[] calldata _tokenIds,
        bytes memory _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
        bytes memory message = abi.encode(
            msg.sender,
            address(issuerState),
            _tokenIds
        );
        require(
            ecrecover(
                keccak256(abi.encodePacked(_prefix, message)),
                _v,
                _r,
                _s
            ) == serverPubKey,
            "Invalid signature"
        );

        uint256 assetId = issuerState.getTokenAsset(_tokenIds[0]);
        uint256 totalClaim = issuerState.totalShareRev(assetId);
        issuerState.setClaimed(assetId, _tokenIds, totalClaim);
        issuerState.claimUnits(address(issuerState), msg.sender, _tokenIds);
    }

    function returnUnits(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external onlyRole(ADMIN) {
        issuerState.claimUnits(_from, _to, _tokenIds);
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
        issuerState.addRevenue(
            msg.sender,
            _assetId,
            _totalRev,
            _amountPerShare
        );
    }

    function claimRevenue(uint256 _assetId, uint256[] calldata _tokenIds)
        external
        whenNotPaused
    {
        issuerState.claimRevenue(msg.sender, _assetId, _tokenIds);
    }

    function updateServer(address _serverPubKey) external onlyRole(ADMIN) {
        serverPubKey = _serverPubKey;
    }

    function setTransfersPaused(bool _paused) external onlyRole(ADMIN) {
        issuerState.setTransfersPaused(_paused);
    }

    function setAssetTransfersPaused(uint256 _assetId, bool _paused)
        external
        onlyRole(ADMIN)
    {
        issuerState.setAssetTransfersPaused(_assetId, _paused);
    }

    function pauseHandler() external onlyRole(ADMIN) {
        _pause();
    }

    function unpauseHandler() external onlyRole(ADMIN) {
        _unpause();
    }
}
