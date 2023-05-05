import { ethers } from "hardhat";
import { Wallet } from "ethers";
import { randomHex } from "../../utils/encoding";

import { faucet } from "../../utils/faucet";

export async function deployContracts() {
  const { provider } = ethers;

  const flinkCollectionOwner: Wallet = new ethers.Wallet(randomHex(32), provider);
  await faucet(flinkCollectionOwner.address, provider);

  // deploy FlinkCollection
  let FlinkCollectionFactory = await ethers.getContractFactory(
    "FlinkCollection",
    flinkCollectionOwner
  );

  const FlinkCollection = await FlinkCollectionFactory.deploy(
    "Flink Collection",
    "FLK",
    ethers.constants.AddressZero,
    "https://temp.com/"
  );

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

  return { flinkCollectionOwner, FlinkCollection, TokenInfoDecoderV1, TokenInfoValidityCheckerV1 };
}
