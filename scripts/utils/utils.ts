import { HardhatEthersProvider } from "@nomicfoundation/hardhat-ethers/internal/hardhat-ethers-provider";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers, run } from "hardhat";
const fs = require("fs");
const path = require("path");

export async function contractAt(
  name: string,
  address: string,
  provider: HardhatEthersProvider | HardhatEthersSigner,
  options?: any
) {
  let contractFactory = await ethers.getContractFactory(name, options);
  if (provider) {
    contractFactory = contractFactory.connect(provider);
  }
  return contractFactory.attach(address);
}

export async function sendTxn(txnPromise: any, label?: string) {
  const txn = await txnPromise;
  console.info(`Sending ${label}...`);
  await txn.wait(1);
  console.info(`... Sent! ${txn.hash}`);
  return txn;
}
