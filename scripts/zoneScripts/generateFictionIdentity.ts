import { time } from "@nomicfoundation/hardhat-network-helpers";
import { ethers } from "ethers";

function generateFictionIdentity(
  chainId: number,
  contractAddress: string,
  authorAddress: string,
  fictionName: string,
  timestamp: number //10 digit
) {
  const identityString = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "address", "address", "string", "uint256"],
    [chainId, contractAddress, authorAddress, fictionName, timestamp]
  );

  const identity = ethers.utils.keccak256(identityString);
  return identity;
}

function main() {
  const chainId = 80001;
  const contractAddress = "0x3ee2c0C4a17cBbC7ae2297F25241cfA1bF3D384E";
  const authorAddress = "0x9175866a922Ef826828C24f42765F261419Dff8D";
  const fictionName = "Hello web3";
  const timestamp = Math.floor(new Date().getTime() / 1000);

  const identity = generateFictionIdentity(
    chainId,
    contractAddress,
    authorAddress,
    fictionName,
    timestamp
  );

  console.log({ identity });
}

main();
