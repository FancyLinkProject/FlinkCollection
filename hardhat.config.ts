import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [{ version: "0.8.17" }],
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
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
      ],
      gas: 10000000,

      //   allowUnlimitedContractSize: true,
    },
    mumbai: {
      chainId: 80001,
      url: process.env.ALCHEMY_API_mumbai,
      accounts: [
        process.env.ACCOUNT_1 as string,
        process.env.ACCOUNT_2 as string,
        process.env.ACCOUNT_3 as string,
        process.env.ACCOUNT_4 as string,
      ],
      gas: 10000000,

      //   allowUnlimitedContractSize: true,
    },
  },
  //   gasReporter: {
  //     outputFile: "gas-report.txt",
  //     enabled: true,
  //     currency: "USD",
  //     noColors: true,
  //     coinmarketcap: process.env.COIN_MARKETCAP_API_KEY || "",
  //     token: "ETH",
  //   },
};
export default config;
