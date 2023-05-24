import hre from "hardhat";
import { ethers } from "ethers";
import { seaportAddress14 } from "../constants/constants";

async function main() {
  const [deployer_1, deployer_2] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer_1.address);
  console.log("Account balance:", (await deployer_1.getBalance()).toString());

  const FlinkCollectionAddress = "0x018105676e72A3063185045ff42F4Be8B21e66A6";
  const FlinkCollectionFactory = await hre.ethers.getContractFactory("FlinkCollection", deployer_1);
  //   create and initialize checkExecutor using multiContractWallet.address
  const FlinkCollection = await FlinkCollectionFactory.attach(FlinkCollectionAddress);
  console.log("FlinkCollection address: ", FlinkCollection.address);

  const tokenInfo = await FlinkCollection.connect(deployer_1).tokenInfo(
    "65793011858312430582592982715830257371966279226709999780235585329012464943105",
    {
      gasLimit: 300000,
    }
  );
  console.log({ tokenInfo });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });
