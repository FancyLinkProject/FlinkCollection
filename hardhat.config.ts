import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
require("dotenv").config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 10,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v6",
  },

  networks: {
    // hardhat: { allowUnlimitedContractSize: true },
    goerli: {
      chainId: 5,
      url: process.env.GOERLI_RPC,
      accounts: [process.env.DEPLOYER as string, process.env.ACCOUNT_1 as string],
      gas: 10000000,
    },
    mumbai: {
      chainId: 80001,
      url: process.env.MUMBAI_RPC,
      accounts: [process.env.DEPLOYER as string, process.env.ACCOUNT_1 as string],
      gas: 1000000,
    },
  },
};
