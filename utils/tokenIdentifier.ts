import { BigNumber } from "ethers";

export function constructTokenId(
  address: string,
  categoryIndex: BigNumber,
  supply: BigNumber
) {
  var tokenId = "";

  tokenId += address;

  tokenId += categoryIndex.toHexString().slice(2).padStart(14, "0");

  tokenId += supply.toHexString().slice(2).padStart(10, "0");

  return BigNumber.from(tokenId);
}
