const { expect } = require("chai");
const help = require("./upgradeable_helper_functions.js");
const { ethers, upgrades } = require("hardhat");

CNR = "0x0cadb0d9e410072325d2acc00aab99eb795a8c86";

describe("Whitelist", function () {
  let owner, provider, investor, asset, testToken;

  beforeEach(async function () {
    [owner, provider, investor] = await ethers.getSigners();
    // CNR = await help.setCNR();
    testToken = await help.setTestToken();

    // asset = await help.setAsset();

    const Rwat = await ethers.getContractFactory("RWAT");
    const rwat = await upgrades.deployProxy(
      Rwat,
      [owner.address, CNR, "tokenName", "tokenSymbol"],
      {
        initializer: "initialize",
      }
    );
    await rwat.deployed();

    let ADMIN = await rwat.ADMIN();
    await rwat.grantRole(ADMIN, owner.address);
  });
  it("Should work", async function () {
    const Rwat = await ethers.getContractFactory("RWAT");
    const rwat = await upgrades.deployProxy(
      Rwat,
      [owner.address, CNR, "tokenName", "tokenSymbol"],
      {
        initializer: "initialize",
      }
    );
    await rwat.deployed();

    let ADMIN = await rwat.ADMIN();
    await rwat.grantRole(ADMIN, owner.address);
    await rwat.grantRole(ADMIN, provider.address);

    await rwat.createAsset(1, 100, testToken.address);
    await rwat.mintAsset(1, 100);
    await rwat.setWhitelisted([investor.address], true);
    console.log(investor.address);
    let units = [1000000000, 1000000001, 1000000002];

    let obj = ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint[]"],
      [investor.address, rwat.address, units]
    );
    const { prefix, v, r, s } = await createSignature(obj);

    await rwat.updateServer(provider.address);

    await rwat.connect(investor).claimUnits(units, prefix, v, r, s);

    expect(await rwat.ownerOf(1000000002)).to.be.equal(investor.address);
    console.log(await rwat.balanceOf(investor.address));

    console.log(
      "hash admin",
      ethers.utils.keccak256(ethers.utils.toUtf8Bytes("ADMIN")),
      rwat.address
    );
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
