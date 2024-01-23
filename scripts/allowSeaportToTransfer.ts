import hre from "hardhat";
import { ethers } from "ethers";
import { seaportAddress15 } from "../constants/constants";
import { contractAt, sendTxn } from "./utils/utils";
import { FancyLinkCollection } from "../typechain";

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const FancyLinkCollectionAddress = "0x1f5c523a3170362dd3db25f224673477111A5BCb";
  const FlinkCollection = (await contractAt(
    "FancyLinkCollection",
    FancyLinkCollectionAddress,
    deployer
  )) as FancyLinkCollection;

  const tx = await sendTxn(
    FlinkCollection.connect(deployer).updateSharedProxyAddress(seaportAddress15, true),
    "FlinkCollection.updateSharedProxyAddress"
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });
