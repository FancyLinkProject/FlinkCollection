import { ethers } from "hardhat";

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

  const lockedAmount = ethers.utils.parseEther("1");

  const TestFactory = await ethers.getContractFactory("Test");
  const test = await TestFactory.deploy();

  await test.deployed();

  const data = { offer: [{ balance: 1 }, { balance: 2 }, { balance: 3 }] };
  //   await test.entry(data);
  await test.entry2(5);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
