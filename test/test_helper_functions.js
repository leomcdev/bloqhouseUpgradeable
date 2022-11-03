// const { ethers } = require("hardhat");

// async function setCNR(){
//   const ChromiaNetResolver = await ethers.getContractFactory("ChromiaNetResolver");
//   const chromiaNetResolver = await ChromiaNetResolver.deploy();
//   await chromiaNetResolver.deployed();
//   return chromiaNetResolver;
// }

// async function setTestToken(){
//   const [owner, addr1, addr2, addr3] = await ethers.getSigners();
//   const TestToken = await ethers.getContractFactory("TestToken");
//   const testToken = await TestToken.deploy();
//   await testToken.deployed();
//   await testToken.connect(owner).faucet();
//   await testToken.connect(addr1).faucet();
//   await testToken.connect(addr2).faucet();
//   await testToken.connect(addr3).faucet();
//   return testToken;
// }

// async function setAssetIssuerState(name, symbol, CNR, default_admin){
//   const State = await ethers.getContractFactory("AssetIssuerState");
//   const state = await State.deploy(name, symbol, CNR, default_admin);
//   await state.deployed();
//   return state;
// }

// async function setAssetHandler(state, default_admin){
//   const Handler = await ethers.getContractFactory("AssetHandler");
//   const handler = await Handler.deploy(state, default_admin);
//   await handler.deployed();
//   return handler;
// }

// async function setWhitelist(_default_admin){
//   const Whitelist = await ethers.getContractFactory("Whitelist");
//   const whitelist = await Whitelist.deploy(_default_admin);
//   await whitelist.deployed();
//   return whitelist;
// }

// async function setWhitelistHandler(_whitelist, _default_admin){
//   const WhitelistHandler = await ethers.getContractFactory("WhitelistHandler");
//   const whitelistHandler = await WhitelistHandler.deploy(_whitelist, _default_admin);
//   await whitelistHandler.deployed();
//   return whitelistHandler;
// }

// async function setResources(_cnr){
//   const Resources = await ethers.getContractFactory("Resources");
//   const resources = await Resources.deploy(_cnr);
//   await resources.deployed();
//   return resources;
// }

// module.exports = { setCNR, setTestToken, setAssetIssuerState, setAssetHandler };
