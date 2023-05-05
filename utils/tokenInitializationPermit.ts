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

  return ethers.utils.keccak256(ethers.utils.toUtf8Bytes(userAddress + entropy + t));
}

export function encodeDataVersion1(
  authorAddress: string,
  fictionName: string,
  volumeName: string,
  chapterName: string,
  volumeNo: number,
  chapterNo: number,
  wordsAmount: number
) {
  const tokenInfo = defaultAbiCoder.encode(
    [
      "tuple(address author, string fictionName, string volumeName, string chapterName, uint256 volumeNo, uint256 chapterNo, uint256 wordsAmount)",
    ],
    [
      {
        authorAddress,
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

export function generateTokenInfoVersion1(
  tokenId: BigNumber,
  version: number,
  data: string,
  tokenUri: string,
  nonce: number,
  signature: string
) {
  const tokenInitializationInfo = defaultAbiCoder.encode(
    [
      "tuple(uint256 tokenId, uint256 version, bytes data, bytes tokenUri, uint256 nonce, bytes signature)",
    ],
    [
      {
        tokenId,
        version,
        data,
        tokenUri,
        nonce,
        signature,
      },
    ]
  );

  return tokenInitializationInfo;
}

export function generateMessageHash(
  chainId: number,
  flinkCollectionAddress: string,
  tokenId: BigNumber,
  version: number,
  data: string,
  tokenUri: string,
  nonce: number
) {
  var msgHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "uint256", "uint256", "bytes", "bytes", "uint256"],
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

export function getDomainSeparator(chainId: number | undefined, contractAddress: string): string {
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "uint256", "address"],
      [DOMAIN_SEPARATOR_TYPEHASH, chainId, contractAddress]
    )
  );
}
