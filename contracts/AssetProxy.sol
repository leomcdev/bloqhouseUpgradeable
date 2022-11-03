// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Asset.sol";
import "./Handler.sol";

// proxy contract
contract AssetProxy is Asset, Handler {
    function initialize(address _default_admin, IAssetIssuerState _IState)
        external
        initializer
    {
        AccessControlUpgradeable.__AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _default_admin);

        Handler.initalizeAddr(_IState);
    }
}
