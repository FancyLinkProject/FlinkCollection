import { ethers } from "hardhat";
import { contractAt, sendTxn } from "./utils/utils";
import { ZeroAddress, keccak256, toUtf8Bytes } from "ethers";
import { InfoVersion, TokenKind } from "../test/constants";
import {
  generateMessageHash,
  generateTokenInfoVersion1,
  nonceGenerator,
} from "../utils/tokenInitializationPermit";
import { FancyLinkCollection } from "../typechain";

async function main() {
  const [deployer, account_1] = await ethers.getSigners();

  const author = account_1;
  console.log(`author: ${author.address}`);

  const FancyLinkCollection = (await contractAt(
    "FancyLinkCollection",
    "0x1f5c523a3170362dd3db25f224673477111A5BCb",
    ethers.provider
  )) as FancyLinkCollection;

  const authorAddress = author.address;
  const content = "hello web3";
  const contentDigest = keccak256(toUtf8Bytes(content));
  const parentId = BigInt(0);
  const supply = BigInt(100);
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
    Number((await ethers.provider.getNetwork()).chainId),
    FancyLinkCollection.target.toString(),
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

  var compactSig = await author.signMessage(msgHash);

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

  // console.log({ tokenInfo });
  // process.exit();

  await sendTxn(
    FancyLinkCollection.connect(author).initializeTokenInfoPermit(tokenInfo),
    "FancyLinkCollection.initializeTokenInfoPermit"
  );
}

main();
