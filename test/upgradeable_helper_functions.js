const { ethers, upgrades } = require("hardhat");

var owner, defaultadmin;
async function setCNR() {
  const ChromiaNetResolver = await ethers.getContractFactory(
    "ChromiaNetResolver"
  );
  const chromiaNetResolver = await ChromiaNetResolver.deploy();
  await chromiaNetResolver.deployed();
  return chromiaNetResolver;
}

async function setTestToken() {
  const [owner, addr1, addr2, addr3] = await ethers.getSigners();
  const TestToken = await ethers.getContractFactory("TestToken");
  const testToken = await TestToken.deploy();
  await testToken.deployed();
  await testToken.connect(owner).faucet();
  await testToken.connect(addr1).faucet();
  await testToken.connect(addr2).faucet();
  await testToken.connect(addr3).faucet();
  return testToken;
}

async function setAsset() {
  const State = await ethers.getContractFactory("Asset");
  const state = await State.deploy();
  await state.deployed();
  return state;
}

async function setHandler() {
  const Handler = await ethers.getContractFactory("Handler");
  const handler = await Handler.deploy();
  await handler.deployed();
  return handler;
}
async function setProxyContract() {
  const Proxy = await ethers.getContractFactory("AssetProxy");
  const proxy = await upgrades.deployProxy(Proxy, [owner, defaultadmin], {
    initializer: "initialize",
  });
  await proxy.deployed();
  return proxy;
}
// async function setWhitelist(_default_admin) {
//   const Whitelist = await ethers.getContractFactory("Whitelist");
//   const whitelist = await Whitelist.deploy(_default_admin);
//   await whitelist.deployed();
//   return whitelist;
// }

// async function setWhitelistHandler(_whitelist, _default_admin) {
//   const WhitelistHandler = await ethers.getContractFactory("WhitelistHandler");
//   const whitelistHandler = await WhitelistHandler.deploy(
//     _whitelist,
//     _default_admin
//   );
//   await whitelistHandler.deployed();
//   return whitelistHandler;
// }

// async function setResources(_cnr) {
//   const Resources = await ethers.getContractFactory("Resources");
//   const resources = await Resources.deploy(_cnr);
//   await resources.deployed();
//   return resources;
// }

module.exports = {
  setCNR,
  setTestToken,
  setAsset,
  setHandler,
  setProxyContract,
};
