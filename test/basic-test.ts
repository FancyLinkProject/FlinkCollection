import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { Wallet } from "ethers";
import { randomHex } from "../utils/encoding";
import hre from "hardhat";
import crypto from "crypto";

import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { faucet } from "../utils/faucet";
import { zeroBytes32 } from "../utils/constants";
import { deployContracts } from "./fixtures/deployContracts";

import { Resolver } from "@ethersproject/providers";
import {
  FlinkCollection,
  TokenInfoDecoderV1,
  TokenInfoValidityCheckerV1,
} from "../typechain-types";
import { TokenInfoVersion } from "./constants";
import { encodeDataVersion1, generateMessageHash } from "../utils/tokenInitializationPermit";

describe("Register controller test", async function () {
  const chainId = hre.network.config.chainId;
  const { provider } = ethers;

  var flinkCollectionOwner: Wallet;
  let FlinkCollection: FlinkCollection;
  let TokenInfoDecoderV1: TokenInfoDecoderV1;
  let TokenInfoValidityCheckerV1: TokenInfoValidityCheckerV1;

  let Author1: Wallet;
  let tokenInfoInitializer: Wallet;

  before(async () => {
    // deploy contract
    ({ flinkCollectionOwner, FlinkCollection, TokenInfoDecoderV1, TokenInfoValidityCheckerV1 } =
      await deployContracts());
    await faucet(Author1.address, provider);
    await faucet(tokenInfoInitializer.address, provider);

    // set tokenInfoDecoder in FlinkCollection
    FlinkCollection.connect(flinkCollectionOwner).setTokenInfoDecoderAddress(
      TokenInfoVersion.V1,
      TokenInfoDecoderV1.address
    );

    // set tokenInfoValidityChecker in FlinkCollection
    FlinkCollection.connect(flinkCollectionOwner).setTokenInfoValidityCheckAddress(
      TokenInfoVersion.V1,
      TokenInfoValidityCheckerV1.address
    );
  });

  describe("initialize token info use initializeTokenInfoPermit", function () {
    var initialzationData;
    const authorAddress = Author1.address;
    const fictionName = "Fancy";
    const volumeName = "Imagination";
    const chapterName = "Challenge";
    const volumeNo = 3;
    const chapterNo = 5;
    const wordsAmount = 12345;
    const tokenUri = "https://www.fancylink/nft/metadata/0x1/";

    const tokenInfoInBytes = encodeDataVersion1(
      authorAddress,
      fictionName,
      volumeName,
      chapterName,
      volumeNo,
      chapterNo,
      wordsAmount
    );

    this.beforeAll(async () => {
      // generate commitment
      generateMessageHash(chainId);
    });

    it("commit", async function () {});
  });
});
