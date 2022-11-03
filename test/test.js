// const { expect } = require("chai");
// const help = require("./test_helper_functions.js");

// describe("Whitelist", function () {
//     let owner, provider, investor, assetIssuerState, assetHandler, testToken;

//     beforeEach(async function () {
//         [owner, provider, investor] = await ethers.getSigners();
//         CNR = await help.setCNR();
//         testToken = await help.setTestToken();
//         assetIssuerState = await help.setAssetIssuerState("Bloqhouse", "BLOQ", CNR.address, owner.address);
//         assetHandler = await help.setAssetHandler(assetIssuerState.address, owner.address);

//         let HANDLER = await assetIssuerState.HANDLER();
//         await assetIssuerState.grantRole(HANDLER, assetHandler.address);

//         let ADMIN = await assetHandler.ADMIN();
//         await assetHandler.grantRole(ADMIN, owner.address);

//       });

//     it("Should work", async function () {
//         await assetHandler.createAsset(1, 100, testToken.address);
//         await assetHandler.mintAsset(1, 100);
//         await assetHandler.setWhitelisted([investor.address], true);

//         let units = [1000000000, 1000000001, 1000000002];

//         let obj = ethers.utils.defaultAbiCoder.encode(
//             ["address", "address", "uint[]"],
//             [investor.address, assetIssuerState.address, units]
//         );
//         const { prefix, v, r, s } = await createSignature(obj);

//         await assetHandler.updateServer(provider.address);

//         await assetHandler.connect(investor).claimUnits(units, prefix, v, r, s);

//         expect(await assetIssuerState.ownerOf(1000000002)).to.be.equal(investor.address);

//     });

//     async function createSignature(obj) {
//         obj = ethers.utils.arrayify(obj);
//         const prefix = ethers.utils.toUtf8Bytes("\x19Ethereum Signed Message:\n" + obj.length);
//         const serverSig = await provider.signMessage(obj);
//         const sig = ethers.utils.splitSignature(serverSig);
//         return { ...sig, prefix };
//       }
// });
