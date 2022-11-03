const { expect } = require("chai");
const help = require("./upgradeable_helper_functions.js");
const { ethers, upgrades } = require("hardhat");

describe("Whitelist", function () {
  let owner, provider, investor, asset, handler, testToken;

  beforeEach(async function () {
    [owner, provider, investor] = await ethers.getSigners();
    // CNR = await help.setCNR();
    testToken = await help.setTestToken();

    asset = await help.setAsset();

    handler = await help.setHandler(asset.address);

    const Proxy = await ethers.getContractFactory("AssetProxy");
    const proxy = await upgrades.deployProxy(
      Proxy,
      [owner.address, handler.address],
      { initializer: "initialize" }
    );
    await proxy.deployed();

    let HANDLER = await handler.HANDLER();
    await proxy.grantRole(HANDLER, provider.address);

    let ADMIN = await handler.ADMIN();
    await proxy.grantRole(ADMIN, owner.address);
  });
  it("Should work", async function () {
    const Proxy = await ethers.getContractFactory("AssetProxy");
    const proxy = await upgrades.deployProxy(
      Proxy,
      [owner.address, handler.address],
      { initializer: "initialize" }
    );
    await proxy.deployed();

    let HANDLER = await handler.HANDLER();
    await proxy.grantRole(HANDLER, owner.address);
    await proxy.grantRole(HANDLER, provider.address);

    let ADMIN = await handler.ADMIN();
    await proxy.grantRole(ADMIN, owner.address);
    await proxy.grantRole(ADMIN, provider.address);

    await proxy.createAsset(1, 100, testToken.address);
    await proxy.mintAsset(1, 100);
    await proxy.setWhitelisted([investor.address], true);
    console.log(investor.address);
    let units = [1000000000, 1000000001, 1000000002];

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint[]"],
      [investor.address, proxy.address, units]
    );
    const { prefix, v, r, s } = await createSignature(obj);

    await proxy.updateServer(provider.address);

    await proxy.connect(investor).claimUnits(units, prefix, v, r, s);

    expect(await proxy.ownerOf(1000000002)).to.be.equal(investor.address);
    console.log(await proxy.balanceOf(investor.address));
  });

  async function createSignature(obj) {
    obj = ethers.utils.arrayify(obj);
    const prefix = ethers.utils.toUtf8Bytes(
      "\x19Ethereum Signed Message:\n" + obj.length
    );
    const serverSig = await provider.signMessage(obj);
    const sig = ethers.utils.splitSignature(serverSig);
    return { ...sig, prefix };
  }
});
