import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";

import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber, Wallet } from "ethers";
import { randomHex } from "../utils/encoding";
import hre from "hardhat";
import crypto from "crypto";

import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { faucet } from "../utils/faucet";
import { zeroBytes32 } from "../utils/constants";
import { deployContracts } from "./fixtures/deployContracts";

import {
  FlinkCollection,
  TokenInfoDecoderV1,
  TokenInfoValidityCheckerV1,
} from "../typechain-types";
import { TokenInfoVersion } from "./constants";
import {
  encodeDataV1,
  generateMessageHash,
  generateTokenInfoVersion1,
  nonceGenerator,
} from "../utils/tokenInitializationPermit";
import { constructTokenId } from "../utils/tokenIdentifier";

describe("Flink collection test", function () {
  const chainId = hre.network.config.chainId;
  const { provider } = ethers;

  var flinkCollectionOwner: Wallet;
  let FlinkCollection: FlinkCollection;
  let TokenInfoDecoderV1: TokenInfoDecoderV1;
  let TokenInfoValidityCheckerV1: TokenInfoValidityCheckerV1;

  let Author1 = new ethers.Wallet(randomHex(32), provider);
  let tokenInfoInitializer = new ethers.Wallet(randomHex(32), provider);

  before(async () => {
    // deploy contract
    ({
      flinkCollectionOwner,
      FlinkCollection,
      TokenInfoDecoderV1,
      TokenInfoValidityCheckerV1,
    } = await deployContracts());
    await faucet(Author1.address, provider);
    await faucet(tokenInfoInitializer.address, provider);

    // set tokenInfoDecoder in FlinkCollection
    FlinkCollection.connect(flinkCollectionOwner).setTokenInfoDecoderAddress(
      TokenInfoVersion.V1,
      TokenInfoDecoderV1.address
    );

    // set tokenInfoValidityChecker in FlinkCollection
    FlinkCollection.connect(
      flinkCollectionOwner
    ).setTokenInfoValidityCheckAddress(
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
    const tokenId = constructTokenId(
      authorAddress,
      BigNumber.from(1),
      BigNumber.from(1)
    );
    const tokenUri = "https://www.fancylink/nft/metadata/0x1/";
    var nonce: string;
    const dataVesion = TokenInfoVersion.V1;

    var data = encodeDataV1(
      authorAddress,
      tokenUri,
      fictionName,
      volumeName,
      chapterName,
      volumeNo,
      chapterNo,
      wordsAmount
    );

    this.beforeAll(async () => {
      nonce = await nonceGenerator(authorAddress);
    });

    it("initialize data", async function () {
      const { msgHash } = generateMessageHash(
        chainId,
        FlinkCollection.address,
        tokenId,
        dataVesion,
        data,
        tokenUri,
        nonce
      );

      var compactSig = await Author1.signMessage(msgHash);

      const tokenInfo = generateTokenInfoVersion1(
        tokenId,
        dataVesion,
        data,
        tokenUri,
        nonce,
        compactSig
      );

      await FlinkCollection.initializeTokenInfoPermit(tokenInfo);

      const tokenInfoInitialized = (await FlinkCollection.tokenInfo(tokenId))
        .initialized;

      expect(tokenInfoInitialized).to.equal(true);
    });
  });
});
