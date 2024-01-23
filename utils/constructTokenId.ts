import { ethers, keccak256 } from "ethers";

export function constructTokenId(
  authorAddress: string,
  contentDigest: string,
  chainId: number,
  flinkCollectionAddress: string,
  parentId: BigInt,
  supply: BigInt
) {
  return keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["address", "bytes32", "uint256", "address", "uint256", "uint256"],
      [authorAddress, contentDigest, chainId, flinkCollectionAddress, parentId, supply]
    )
  );
}
