// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Asset.sol";

/**
 * @title Real world asset tokenization contract to fractionalize real-estate into shares.
 * @dev Should hold no data directly to be easily upgraded
 *
 * Upgrading this contract and adding new parent can be done while there is no dynamic
 * state variables in this contract. All new inherited contracts must be appeneded
 * to the currently inherited contracts.
 */
contract RWAT is Asset {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This handles the initialize call out to inherited contracts as needed.
     */
    function initialize(
        address _default_admin,
        ICNR _CNR,
        string memory name_,
        string memory symbol_
    ) external initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _default_admin);

        __ERC721_init(name_, symbol_);

        initializeCNR(_CNR);

        __Pausable_init();
    }

    function setWhitelisted(address[] calldata _users, bool _isWhitelisted)
        external
        onlyRole(ADMIN)
    {
        _setWhitelisted(_users, _isWhitelisted);
    }

    /**
     * @notice Creates asset with with ID and tokenCap.
     * @dev Adds 9 zeros to the ID.
     */
    function createAsset(
        uint256 _assetId,
        uint256 _tokenCap,
        IERC20Upgradeable _revToken
    ) external onlyRole(ADMIN) {
        _createAsset(_assetId, _tokenCap, _revToken);
    }

    /**
     * @notice Updates the current asset cap.
     * @dev 9 zeros are added.
     */
    function updateAssetCap(uint256 _assetId, uint256 _tokenCap)
        external
        onlyRole(ADMIN)
    {
        _updateAssetTokenCap(_assetId, _tokenCap);
    }

    /**
     * @notice Mints assets with respective ID as long as the max amount
     * of minted assets has not been exceeded.
     */
    function mintAsset(uint256 _assetId, uint256 _amount)
        external
        onlyRole(ADMIN)
    {
        _mintAsset(_assetId, _amount, address(this));
    }

    /**
     * @notice Lets user claim their total share upon the current timeframe.
     * @dev Requires server sig and the token asset to exist.
     */
    function claimUnits(
        uint256[] calldata _tokenIds,
        bytes memory _prefix,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
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

    /**
     * @dev Returns the unit to this contract from a investor.
     */
    function returnUnits(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external onlyRole(ADMIN) {
        _claimUnits(_from, _to, _tokenIds);
    }

    /**
     * @notice Calculates and adds the revenue to a asset.
     */
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

    /**
     * @notice User can claim its total revenue
     */
    function claimRevenue(uint256 _assetId, uint256[] calldata _tokenIds)
        external
        whenNotPaused
    {
        _claimRevenue(msg.sender, _assetId, _tokenIds);
    }

    function updateServer(address _serverPubKey) external onlyRole(ADMIN) {
        _updateServer(_serverPubKey);
    }

    /**
     * @notice Set transfers paused for the whole contract
     */
    function setTransfersPaused(bool _paused) external onlyRole(ADMIN) {
        _setTransfersPaused(_paused);
    }

    /**
     * @notice Set transfers paused for a asset
     */
    function setAssetTransfersPaused(uint256 _assetId, bool _paused)
        external
        onlyRole(ADMIN)
    {
        _setAssetTransfersPaused(_assetId, _paused);
    }

    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    /**
     * @notice Set and update name and symbol after deployment!
     */
    function setNameAndSymbol(string memory _name, string memory _symbol)
        public
        onlyRole(ADMIN)
    {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view override returns (string memory) {
        return name_;
    }

    function symbol() public view override returns (string memory) {
        return symbol_;
    }

    uint256[1000] private __gap;
}
