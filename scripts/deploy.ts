import hre, { ethers, upgrades } from "hardhat";

import { seaportAddress15 } from "../constants/constants";
import { FlinkCollection } from "../typechain-types";
import { ZeroAddress } from "ethers";

async function main() {
  let FlinkCollection: FlinkCollection;

  const [flinkCollectionOwner] = await ethers.getSigners();

  // deploy FlinkCollection
  let FlinkCollectionFactory = await ethers.getContractFactory(
    "FancyLinkCollection",
    flinkCollectionOwner
  );

  FlinkCollection = (await upgrades.deployProxy(
    FlinkCollectionFactory,
    ["FancyLinkCollection", ZeroAddress],
    { kind: "transparent", initializer: "initialize" }
  )) as any as FlinkCollection;

  console.log(`FlinkCollection address: ${await FlinkCollection.getAddress()}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error });
    process.exit(1);
  });
