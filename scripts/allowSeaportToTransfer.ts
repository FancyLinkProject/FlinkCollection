import hre from "hardhat";
import { ethers } from "ethers";
import { seaportAddress14 } from "../constants/constants";

async function main() {
  const [deployer_1, deployer_2] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer_1.address);
  console.log("Account balance:", (await deployer_1.getBalance()).toString());

  const FlinkCollectionAddress = "0xEE91F76B3Fc86A4e66c04109aaEBe8a0aF91ecb4";
  const FlinkCollectionFactory = await hre.ethers.getContractFactory("FlinkCollection", deployer_1);
  //   create and initialize checkExecutor using multiContractWallet.address
  const FlinkCollection = await FlinkCollectionFactory.attach(FlinkCollectionAddress);
  console.log("FlinkCollection address: ", FlinkCollection.address);

  const tx = await FlinkCollection.connect(deployer_1).addSharedProxyAddress(seaportAddress14, {
    gasLimit: 300000,
  });
  console.log({ tx });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });
