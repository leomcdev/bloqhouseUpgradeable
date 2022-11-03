// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "../interfaces/ICNR.sol";

// contract AssetIssuerState is ERC721, AccessControl {
//     bytes32 public constant HANDLER = keccak256("HANDLER");

//     ICNR private CNR;
//     mapping(address => bool) public isWhitelisted;

//     bool pausedTransfers = false;
//     mapping(uint256 => bool) public assetPaused;

//     mapping(uint256 => uint256) public nextId;
//     mapping(uint256 => uint256) public lastId;

//     mapping(uint256 => IERC20) public assetRevToken;
//     mapping(uint256 => uint256) public totalShareRev;
//     mapping(uint256 => uint256) public claimedRev;

//     constructor(
//         string memory _name,
//         string memory _symbol,
//         ICNR _CNR,
//         address _default_admin
//     ) ERC721(_name, _symbol) {
//         CNR = _CNR;
//         _grantRole(DEFAULT_ADMIN_ROLE, _default_admin);
//     }

//     function createAsset(
//         uint256 _assetId,
//         uint256 _tokenCap,
//         IERC20 _revToken
//     ) external onlyRole(HANDLER) {
//         require(nextId[_assetId] == 0, "Asset already exists");
//         assetRevToken[_assetId] = _revToken;
//         nextId[_assetId] = _assetId * 1_000_000_000;
//         lastId[_assetId] = _assetId * 1_000_000_000 + _tokenCap;
//     }

//     function updateAssetTokenCap(uint256 _assetId, uint256 _tokenCap)
//         external
//         onlyRole(HANDLER)
//     {
//         require(
//             nextId[_assetId] <= _assetId * 1_000_000_000 + _tokenCap,
//             "Asset cap can not be lower than minted amount"
//         );
//         lastId[_assetId] = _assetId * 1_000_000_000 + _tokenCap;
//     }

//     function mintAsset(
//         uint256 _assetId,
//         uint256 _amount,
//         address _to
//     ) external onlyRole(HANDLER) {
//         require(
//             (nextId[_assetId] + _amount) <= lastId[_assetId],
//             "Amount exceeds max"
//         );
//         for (uint256 i = 0; i < _amount; i++) {
//             _mint(_to, nextId[_assetId]);
//             nextId[_assetId]++;
//         }
//     }

//     function setWhitelisted(address[] calldata _users, bool _whitelisted)
//         external
//         onlyRole(HANDLER)
//     {
//         uint256 length = _users.length;
//         for (uint256 i = 0; i < length; i++) {
//             isWhitelisted[_users[i]] = _whitelisted;
//         }
//     }

//     function claimUnits(
//         address _from,
//         address _to,
//         uint256[] calldata _tokenIds
//     ) external onlyRole(HANDLER) {
//         uint256 length = _tokenIds.length;
//         for (uint256 i = 0; i < length; i++) {
//             _transfer(_from, _to, _tokenIds[i]);
//         }
//     }

//     function setClaimed(
//         uint256 _assetId,
//         uint256[] calldata _tokenIds,
//         uint256 _amount
//     ) external onlyRole(HANDLER) {
//         uint256 length = _tokenIds.length;
//         for (uint256 i = 0; i < length; i++) {
//             require(
//                 getTokenAsset(_tokenIds[i]) == _assetId,
//                 "Invalid token for asset"
//             );
//             claimedRev[_tokenIds[i]] = _amount;
//         }
//     }

//     function addRevenue(
//         address _from,
//         uint256 _assetId,
//         uint256 _totalRev,
//         uint256 _amountPerToken
//     ) external onlyRole(HANDLER) {
//         totalShareRev[_assetId] += _amountPerToken;
//         assetRevToken[_assetId].transferFrom(_from, address(this), _totalRev);
//     }

//     function claimRevenue(
//         address _owner,
//         uint256 _assetId,
//         uint256[] calldata _tokenIds
//     ) external onlyRole(HANDLER) {
//         require(isWhitelisted[_owner], "Owner is not whitelisted");
//         uint256 totalToGet;
//         uint256 length = _tokenIds.length;
//         uint256 totalAssetRev = totalShareRev[_assetId];
//         for (uint256 i = 0; i < length; i++) {
//             require(ownerOf(_tokenIds[i]) == _owner, "Invalid token owner");
//             require(
//                 getTokenAsset(_tokenIds[i]) == _assetId,
//                 "Invalid token for asset"
//             );
//             totalToGet += totalAssetRev - claimedRev[_tokenIds[i]];
//             claimedRev[_tokenIds[i]] = totalAssetRev;
//         }
//         assetRevToken[_assetId].transferFrom(address(this), _owner, totalToGet);
//     }

//     function setTransfersPaused(bool _paused) external onlyRole(HANDLER) {
//         pausedTransfers = _paused;
//     }

//     function setAssetTransfersPaused(uint256 _assetId, bool _paused)
//         external
//         onlyRole(HANDLER)
//     {
//         assetPaused[_assetId] = _paused;
//     }

//     function _beforeTokenTransfer(
//         address from,
//         address to,
//         uint256 tokenId
//     ) internal override {
//         super._beforeTokenTransfer(from, to, tokenId);
//         if (!(from == address(0) || from == address(this))) {
//             require(!pausedTransfers, "Transfers are currently paused");
//             require(!assetPaused[getTokenAsset(tokenId)], "Asset is paused");
//             require(
//                 isWhitelisted[from] && isWhitelisted[to],
//                 "Invalid token transfer"
//             );
//         }
//     }

//     function getTokenAsset(uint256 _tokenId) public pure returns (uint256) {
//         return _tokenId / 1_000_000_000;
//     }

//     function tokenURI(uint256 _tokenId)
//         public
//         view
//         override
//         returns (string memory)
//     {
//         require(
//             _exists(_tokenId),
//             "ERC721Metadata: URI query for nonexistent token"
//         );
//         return ICNR(CNR).getNFTURI(address(this), _tokenId);
//     }

//     function supportsInterface(bytes4 interfaceId)
//         public
//         view
//         virtual
//         override(ERC721, AccessControl)
//         returns (bool)
//     {
//         return super.supportsInterface(interfaceId);
//     }
// }
