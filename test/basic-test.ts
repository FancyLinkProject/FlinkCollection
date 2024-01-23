import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

import { expect } from "chai";
import { ethers } from "hardhat";

import hre from "hardhat";

import { ZeroAddress, keccak256, toUtf8Bytes } from "ethers";
import { deployContracts } from "./fixtures/deployContracts";

import { InfoVersion, TokenKind } from "./constants";
import {
  generateBeforeTransferData,
  generateMessageHash,
  generateTokenInfoVersion1,
  nonceGenerator,
} from "../utils/tokenInitializationPermit";

describe("Flink collection test", function () {
  const chainId = hre.network.config.chainId;

  describe("initialize token info use initializeTokenInfoPermit", function () {
    it("success with correct parameters", async function () {
      const {
        flinkCollectionOwner,
        FlinkCollection,
        TokenInfoDecoderV1,
        TokenInfoValidityCheckerV1,
        addr1,
        addr2,
        addr3,
      } = await loadFixture(deployContracts);

      const authorAddress = addr1.address;
      const content = "hello web3";
      const contentDigest = keccak256(toUtf8Bytes(content));
      const parentId = BigInt(1);
      const supply = BigInt(10);
      const kind = TokenKind.Chapter;
      const version = InfoVersion.V1;
      const tokenUri = "https://www.fancylink/nft/metadata/0x1/";
      const extraData = "0x";
      const zone = ZeroAddress;
      const domainName = "FancyLinkCollection";
      const domainVersion = "1";
      var nonce: string;

      nonce = await nonceGenerator(authorAddress);

      const { msgHash, tokenId } = generateMessageHash(
        chainId,
        FlinkCollection.target.toString(),
        authorAddress,
        contentDigest,
        parentId,
        supply,
        kind,
        version,
        zone,
        extraData,
        tokenUri,
        nonce,
        domainName,
        domainVersion
      );

      var compactSig = await addr1.signMessage(msgHash);

      const tokenInfo = generateTokenInfoVersion1(
        authorAddress,
        contentDigest,
        parentId,
        supply,
        kind,
        version,
        zone,
        extraData,
        tokenUri,
        nonce,
        compactSig
      );

      await FlinkCollection.initializeTokenInfoPermit(tokenInfo);

      const contractTokenInfo = await FlinkCollection.tokenInfo(tokenId);
      expect(contractTokenInfo.author).to.equal(authorAddress);
      expect(contractTokenInfo.contentDigest).to.equal(contentDigest);
      expect(contractTokenInfo.parentId).to.equal(parentId);
      expect(contractTokenInfo.supply).to.equal(supply);
      expect(contractTokenInfo.kind).to.equal(kind);
      expect(contractTokenInfo.version).to.equal(version);
      expect(contractTokenInfo.extraData).to.equal(extraData);
      expect(contractTokenInfo.initialized).to.equal(true);
    });

    it("revert with invalid signature", async function () {
      const {
        flinkCollectionOwner,
        FlinkCollection,
        TokenInfoDecoderV1,
        TokenInfoValidityCheckerV1,
        addr1,
        addr2,
        addr3,
      } = await loadFixture(deployContracts);

      const authorAddress = addr1.address;
      const content = "hello web3";
      const contentDigest = keccak256(toUtf8Bytes(content));
      const parentId = BigInt(1);
      const supply = BigInt(10);
      const kind = TokenKind.Chapter;
      const version = InfoVersion.V1;
      const tokenUri = "https://www.fancylink/nft/metadata/0x1/";
      const extraData = "0x";
      const zone = ZeroAddress;
      const domainName = "FancyLink";
      const domainVersion = "1";
      var nonce: string;

      nonce = await nonceGenerator(authorAddress);

      const { msgHash, tokenId } = generateMessageHash(
        123,
        FlinkCollection.target.toString(),
        authorAddress,
        contentDigest,
        parentId,
        supply,
        kind,
        version,
        zone,
        extraData,
        tokenUri,
        nonce,
        domainName,
        domainVersion
      );

      var compactSig = await addr1.signMessage(msgHash);

      const tokenInfo = generateTokenInfoVersion1(
        authorAddress,
        contentDigest,
        parentId,
        supply,
        kind,
        version,
        zone,
        extraData,
        tokenUri,
        nonce,
        compactSig
      );

      await expect(FlinkCollection.initializeTokenInfoPermit(tokenInfo)).to.be.revertedWith(
        "FLK#initializeTokenInfoPermit: Not signer"
      );
    });
  });
});
