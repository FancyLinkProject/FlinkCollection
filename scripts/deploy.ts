import hre, { upgrades } from "hardhat";
import { ethers } from "ethers";
import { seaportAddress15 } from "../constants/constants";
import { FlinkCollection } from "../typechain-types";

async function main() {
  const [deployer_1, deployer_2] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer_1.address);
  console.log("Account balance:", (await deployer_1.getBalance()).toString());

  const FlinkCollectionFactory = await hre.ethers.getContractFactory("FlinkCollection", deployer_1);

  const FlinkCollection = (await upgrades.deployProxy(
    FlinkCollectionFactory,
    ["Flink Collection", "FLK", ethers.constants.AddressZero, "https://metadata.fancylink.xyz/"],
    { kind: "uups", initializer: "initialize" }
  )) as FlinkCollection;
  console.log("FlinkCollection address: ", FlinkCollection.address);
  

  //   deploy TokenInitializationZone
  const TokenInitializationZoneFactory = await hre.ethers.getContractFactory(
    "TokenInitializationZone",
    deployer_1
  );
  //   create and initialize checkExecutor using multiContractWallet.address
  const TokenInitializationZone = await TokenInitializationZoneFactory.deploy(
    FlinkCollection.address
  );
  console.log("TokenInitializationZone address: ", TokenInitializationZone.address);

  const tx = await FlinkCollection.connect(deployer_1).addSharedProxyAddress(seaportAddress15, {
    gasLimit: 300000,
  });

  console.log(tx);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });
