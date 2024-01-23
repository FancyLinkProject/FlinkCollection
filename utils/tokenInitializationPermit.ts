import { ethers } from "hardhat";
import crypto from "crypto";
import { DOMAIN_SEPARATOR_TYPEHASH } from "./constants";
import { AbiCoder, getBytes, keccak256, toUtf8Bytes } from "ethers";
import { InfoVersion, TokenKind } from "../test/constants";

// get a random nonce
export async function nonceGenerator(userAddress: string): Promise<string> {
  var entropy = "";
  await crypto.randomBytes(48, function (err, buffer) {
    entropy = buffer.toString("hex");
  });

  const t = new Date().getTime().toString();

  return keccak256(toUtf8Bytes(userAddress + entropy + t));
}

export function encodeDataV1(
  authorAddress: string,
  fictionName: string,
  volumeName: string,
  chapterName: string,
  volumeNo: number,
  chapterNo: number
) {
  const tokenInfo = AbiCoder.defaultAbiCoder().encode(
    [
      "tuple(address author, string fictionName, string volumeName, string chapterName, uint256 volumeNo, uint256 chapterNo)",
    ],
    [
      {
        author: authorAddress,
        fictionName,
        volumeName,
        chapterName,
        volumeNo,
        chapterNo,
      },
    ]
  );

  return tokenInfo;
}

export interface TokenInitializationInfo {
  author: string;
  contentDigest: string;
  parentId: BigInt;
  supply: BigInt;
  kind: TokenKind;
  version: InfoVersion;
  extraData: string;
  tokenUri: string;
  nonce: string;
  signature: string;
}

export function generateSingleTokenInitializeInfoVersion1(
  tokenInitializationInfo: TokenInitializationInfo,
  proofLs: string[]
) {
  const encodedSingleTokenInitializationInfo = AbiCoder.defaultAbiCoder().encode(
    [
      "tuple(address author, bytes32 contentDigest, uint parentId, uint supply, uint kind, uint version, bytes extraData, string tokenUri, uint nonce, bytes signature)[]",
      "bytes32[][]",
    ],
    [[tokenInitializationInfo], [proofLs]]
  );

  return encodedSingleTokenInitializationInfo;
}

export function generateBatchTokenInitializationInfoVersion1(
  TokenInitializationInfoLs: TokenInitializationInfo[],
  proofLs: string[][]
) {
  const encodedBatchTokenInitializationInfo = AbiCoder.defaultAbiCoder().encode(
    [
      "tuple(uint256 tokenId, uint256 version, bytes data, string tokenUri, uint256 nonce, bytes signature)[]",
      "bytes32[][]",
    ],
    [TokenInitializationInfoLs, proofLs]
  );

  return encodedBatchTokenInitializationInfo;
}

export function generateBeforeTransferData(tokenInitializationInfo: TokenInitializationInfo) {
  const encodedSingleTokenInitializationInfo = AbiCoder.defaultAbiCoder().encode(
    [
      "tuple(address author, bytes32 contentDigest, uint parentId, uint supply, uint kind, uint version, bytes extraData, string tokenUri, uint nonce, bytes signature)[]",
    ],
    [[tokenInitializationInfo]]
  );

  return encodedSingleTokenInitializationInfo;
}

export function generateMessageHash(
  chainId: number | undefined,
  flinkCollectionAddress: string,
  authorAddress: string,
  contentDigest: string,
  parentId: BigInt,
  supply: BigInt,
  kind: TokenKind,
  version: InfoVersion,
  zone: string,
  extraData: string,
  tokenUri: string,
  nonce: string,
  domainName: string,
  domainVersion: string
) {
  if (!chainId) {
    throw "invalid chainId";
  }

  var msgHash = keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      [
        "bytes32",
        "address",
        "bytes32",
        "uint256",
        "uint256",
        "uint256",
        "uint256",
        "address",
        "bytes",
        "string",
        "uint256",
      ],
      [
        DOMAIN_SEPARATOR_TYPEHASH,
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
      ]
    )
  );

  const domainSeparator = getDomainSeparator(
    chainId,
    flinkCollectionAddress,
    domainName,
    domainVersion
  );

  const msgHash_2 = keccak256(
    ethers.solidityPacked(
      ["bytes1", "bytes1", "bytes32", "bytes32"],
      ["0x19", "0x01", domainSeparator, msgHash]
    )
  );

  return {
    msgHash: ethers.getBytes(msgHash_2),
    tokenId: keccak256(
      ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "bytes32", "uint256", "address", "uint256", "uint256"],
        [authorAddress, contentDigest, chainId, flinkCollectionAddress, parentId, supply]
      )
    ),
  };
}

export function getDomainSeparator(
  chainId: number | undefined,
  contractAddress: string,
  name: string,
  version: string
): string {
  return keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes32", "bytes32", "bytes32", "address", "uint256"],
      [
        DOMAIN_SEPARATOR_TYPEHASH,
        keccak256(toUtf8Bytes(name)),
        keccak256(toUtf8Bytes(version)),
        contractAddress,
        chainId,
      ]
    )
  );
}

export function generateZoneHash(
  tokenId: string,
  version: number,
  data: string,
  uri: string
): string {
  return keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["uint256", "tuple(uint256 version, bytes data, bool initialized)", "string"],
      [tokenId, { version, data, initialized: true }, uri]
    )
  );
}

export function generateTokenInfoVersion1(
  authorAddress: string,
  contentDigest: string,
  parentId: bigint,
  supply: bigint,
  kind: TokenKind,
  version: InfoVersion,
  zone: string,
  extraData: string,
  tokenUri: string,
  nonce: string,
  compactSig: string
) {
  return {
    author: authorAddress,
    contentDigest,
    parentId,
    supply,
    kind,
    version,
    zone,
    extraData,
    tokenUri,
    nonce,
    signature: compactSig,
  };
}
