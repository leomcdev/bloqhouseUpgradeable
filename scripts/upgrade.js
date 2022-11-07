const { ethers, upgrades } = require("hardhat");

const PROXY = "0x4cD3C332E82a87EbdCC0b49B5A17B96CCd47810B";

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
