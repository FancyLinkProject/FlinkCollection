import hre from "hardhat";
import { ethers } from "ethers";

async function main() {
  const [deployer_1, deployer_2] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer_1.address);
  console.log("Account balance:", (await deployer_1.getBalance()).toString());
  const FlinkCollectionFactory = await hre.ethers.getContractFactory("FlinkCollection", deployer_1);
  //   create and initialize checkExecutor using multiContractWallet.address
  const FlinkCollection = await FlinkCollectionFactory.deploy(
    "Flink Collection",
    "FLK",
    ethers.constants.AddressZero,
    "https://temp.com/"
  );
  console.log(FlinkCollection.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });
