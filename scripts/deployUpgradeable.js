require("dotenv").config();
const path = require("path");

const { ethers, upgrades } = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
  await ethers.getSigners();

  const Asset = await ethers.getContractFactory("Asset");
  const asset = await Asset.deploy();
  await asset.deployed();
  console.log("asset Contract deployed to:", asset.address);

  const Handler = await ethers.getContractFactory("Handler");
  const handler = await Handler.deploy();
  await handler.deployed();
  console.log("handler Contract deployed to:", handler.address);

  const Proxy = await ethers.getContractFactory("AssetProxy");
  const proxy = await upgrades.deployProxy(
    Proxy,
    [owner.address, handler.address],
    { initializer: "initialize" }
  );
  await proxy.deployed();
  console.log("proxy Contract deployed to:", proxy.address);

  console.log("owner address", owner.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/deployUpgradeable.js --network BSCTestnet
// npx hardhat verify --network BSCTestnet
