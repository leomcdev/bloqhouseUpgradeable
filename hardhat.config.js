require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
module.exports = {
  // defaultNetwork: "",
  networks: {
    hardhat: {},
    // matic: {
    //   url: "https://rpc-mumbai.maticvigil.com",
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    // goerli: {
    //   url: "https://goerli.infura.io/v3/",
    //   accounts: [process.env.PRIVATE_KEY],
    // },
  },
  // etherscan: {
  //   apiKey: process.env.POLYGONSCAN_API_KEY,
  // },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
