import { ethers, upgrades } from "hardhat";
import { randomHex } from "../../utils/encoding";

import { FlinkCollection } from "../../typechain-types";
import { ZeroAddress } from "ethers";

export async function deployContracts() {
  const { provider } = ethers;
  let FlinkCollection: FlinkCollection;

  const [flinkCollectionOwner, addr1, addr2, addr3] = await ethers.getSigners();

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
    FlinkCollection.target
  );

  return {
    flinkCollectionOwner,
    FlinkCollection,
    TokenInfoDecoderV1,
    TokenInfoValidityCheckerV1,
    TokenInitializationZone,
    addr1,
    addr2,
    addr3,
  };
}

deployContracts();
