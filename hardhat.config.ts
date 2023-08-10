import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
require("dotenv").config();

module.exports = {
  solidity: {
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
    compilers: [
      {
        version: "0.8.17",
        settings: {
          viaIR: true,
          optimizer: { enabled: true, runs: 100 },
          metadata: {
            bytecodeHash: "none",
          },
          outputSelection: {
            "*": {
              "*": ["evm.assembly", "irOptimized", "devdoc"],
            },
          },
        },
      },
    ],
  },

  networks: {
    hardhat: { allowUnlimitedContractSize: true },
    goerli: {
      chainId: 5,
      url: process.env.ALCHEMY_API,
      accounts: [
        process.env.ACCOUNT_1 as string,
        process.env.ACCOUNT_2 as string,
        process.env.ACCOUNT_3 as string,
        process.env.ACCOUNT_4 as string,
        process.env.ACCOUNT_5 as string,
      ],
      gas: 10000000,
    },
    mumbai: {
      chainId: 80001,
      url: process.env.MUMBAI_API,
      accounts: [
        process.env.ACCOUNT_1 as string,
        process.env.ACCOUNT_2 as string,
        process.env.ACCOUNT_3 as string,
        process.env.ACCOUNT_4 as string,
        process.env.ACCOUNT_5 as string,
      ],
      gas: 1000000,
    },
  },
};
