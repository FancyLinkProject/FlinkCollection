import { defaultAbiCoder } from "ethers/lib/utils";
import { ethers } from "hardhat";
import crypto from "crypto";
import { DOMAIN_SEPARATOR_TYPEHASH } from "./constants";
import { BigNumber } from "ethers";

// get a random nonce
export async function nonceGenerator(userAddress: string): Promise<string> {
  var entropy = "";
  await crypto.randomBytes(48, function (err, buffer) {
    entropy = buffer.toString("hex");
  });

  const t = new Date().getTime().toString();

  return ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes(userAddress + entropy + t)
  );
}

export function encodeDataV1(
  authorAddress: string,
  tokenUri: string,
  fictionName: string,
  volumeName: string,
  chapterName: string,
  volumeNo: number,
  chapterNo: number,
  wordsAmount: number
) {
  const tokenInfo = defaultAbiCoder.encode(
    [
      "tuple(address author, string tokenUri, string fictionName, string volumeName, string chapterName, uint256 volumeNo, uint256 chapterNo, uint256 wordsAmount)",
    ],
    [
      {
        author: authorAddress,
        tokenUri,
        fictionName,
        volumeName,
        chapterName,
        volumeNo,
        chapterNo,
        wordsAmount,
      },
    ]
  );

  return tokenInfo;
}

export interface TokenInitializationInfo {
  tokenId: BigNumber;
  version: number;
  data: string;
  tokenUri: string;
  nonce: string;
  signature: string;
}

export function generateSingleTokenInfoVersion1(
  tokenInitializationInfo: TokenInitializationInfo
) {
  const encodedSingleTokenInitializationInfo = defaultAbiCoder.encode(
    [
      "tuple(uint256 tokenId, uint256 version, bytes data, string tokenUri, uint256 nonce, bytes signature)",
    ],
    [tokenInitializationInfo]
  );

  return encodedSingleTokenInitializationInfo;
}

export function generateBatchTokenInfoVersion1(
  TokenInitializationInfoLs: TokenInitializationInfo[]
) {
  const encodedBatchTokenInitializationInfo = defaultAbiCoder.encode(
    [
      "tuple(uint256 tokenId, uint256 version, bytes data, string tokenUri, uint256 nonce, bytes signature)[]",
    ],
    [TokenInitializationInfoLs]
  );

  return encodedBatchTokenInitializationInfo;
}

export function generateMessageHash(
  chainId: number | undefined,
  flinkCollectionAddress: string,
  tokenId: BigNumber,
  version: number,
  data: string,
  tokenUri: string,
  nonce: string
) {
  if (!chainId) {
    throw "invalid chainId";
  }

  var msgHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "uint256", "uint256", "bytes", "string", "uint256"],
      [DOMAIN_SEPARATOR_TYPEHASH, tokenId, version, data, tokenUri, nonce]
    )
  );

  const domainSeparator = getDomainSeparator(chainId, flinkCollectionAddress);

  const msgHash_2 = ethers.utils.keccak256(
    ethers.utils.solidityPack(
      ["bytes1", "bytes1", "bytes32", "bytes32"],
      ["0x19", "0x01", domainSeparator, msgHash]
    )
  );

  return { msgHash: ethers.utils.arrayify(msgHash_2) };
}

export function getDomainSeparator(
  chainId: number | undefined,
  contractAddress: string
): string {
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "uint256", "address"],
      [DOMAIN_SEPARATOR_TYPEHASH, chainId, contractAddress]
    )
  );
}