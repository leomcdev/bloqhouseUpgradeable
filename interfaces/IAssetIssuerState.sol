// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAssetIssuerState {
    function createAsset(
        uint256 _assetId,
        uint256 _tokenCap,
        IERC20 _revToken
    ) external;

    function updateAssetTokenCap(uint256 _assetId, uint256 _tokenCap) external;

    function mintAsset(
        uint256 _assetId,
        uint256 _amount,
        address _to
    ) external;

    function claimUnits(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external;

    function addRevenue(
        address _from,
        uint256 _assetId,
        uint256 _totalRev,
        uint256 _RevPerShare
    ) external;

    function claimRevenue(
        address _owner,
        uint256 _assetId,
        uint256[] calldata _tokenIds
    ) external;

    function getTokenAsset(uint256 _tokenId) external pure returns (uint256);

    function setClaimed(
        uint256 _assetId,
        uint256[] calldata _tokenIds,
        uint256 _amount
    ) external;

    function totalShareRev(uint256 _assetId) external view returns (uint256);

    function setWhitelisted(address[] calldata _users, bool _whitelisted)
        external;

    function setTransfersPaused(bool _paused) external;

    function setAssetTransfersPaused(uint256 _assetId, bool _paused) external;

    function initializeName(string memory _name, string memory _symbol)
        external;
}
