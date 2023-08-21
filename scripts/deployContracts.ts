import { ethers, upgrades } from "hardhat";
import { Wallet } from "ethers";
import { randomHex } from "../../utils/encoding";

import { faucet } from "../../utils/faucet";
import { FlinkCollection } from "../../typechain-types";

export async function deployContracts() {
  const { provider } = ethers;
  let FlinkCollection: FlinkCollection;

  const flinkCollectionOwner: Wallet = new ethers.Wallet(randomHex(32), provider);
  await faucet(flinkCollectionOwner.address, provider);

  // deploy FlinkCollection
  let FlinkCollectionFactory = await ethers.getContractFactory(
    "FlinkCollection",
    flinkCollectionOwner
  );

  FlinkCollection = (await upgrades.deployProxy(
    FlinkCollectionFactory,
    ["Flink Collection", "FLK", ethers.constants.AddressZero, "https://metadata.fancylink.xyz/"],
    { kind: "uups", initializer: "initialize" }
  )) as FlinkCollection;

  //   deploy tokenInfoDecoder
  let TokenInfoDecoderV1Factory = await ethers.getContractFactory(
    "TokenInfoDecoderV1",
    flinkCollectionOwner
  );

  const TokenInfoDecoderV1 = await TokenInfoDecoderV1Factory.deploy();

  //   deploy tokenInfoValidityChecker
  let TokenInfoValidityCheckerV1Factory = await ethers.getContractFactory(
    "TokenInfoValidityCheckerV1",
    flinkCollectionOwner
  );

  const TokenInfoValidityCheckerV1 = await TokenInfoValidityCheckerV1Factory.deploy();

  //   deploy TokenInitializationZone
  let TokenInitializationZoneFactory = await ethers.getContractFactory(
    "TokenInitializationZone",
    flinkCollectionOwner
  );

  const TokenInitializationZone = await TokenInitializationZoneFactory.deploy(
    FlinkCollection.address
  );

  return {
    flinkCollectionOwner,
    FlinkCollection,
    TokenInfoDecoderV1,
    TokenInfoValidityCheckerV1,
    TokenInitializationZone,
  };
}

deployContracts();
