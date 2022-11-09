const { ethers, upgrades } = require("hardhat");

const PROXY = "0x88B70d25c0dE89672aA02085B281244E13Df7A66";

async function setProxy() {
  const C = await ethers.getContractFactory("RWAT");
  const c = await upgrades.upgradeProxy(PROXY, C);
  await c.deployed();
  return c;
}

async function main() {
  let C = await setProxy();
  console.log("Contract address: ", C.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/upgrade.js --network BSCTestnet
// npx hardhat verify --network BSCTestnet
