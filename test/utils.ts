import { BigNumber, Wallet } from "ethers";
import { constructTokenId } from "../utils/tokenIdentifier";
import {
  encodeDataV1,
  generateMessageHash,
  generateSingleTokenInfoVersion1,
  nonceGenerator,
} from "../utils/tokenInitializationPermit";
import { FlinkCollection } from "../typechain-types";
import { chainIdOption } from "../types/type";
import { TokenInfoVersion } from "./constants";

export async function initializeTokenInfo({
  author,
  FlinkCollection,
  chainId,
  dataVesion,
  tokenIndex,
  tokenSupply,
}: {
  author: Wallet;
  FlinkCollection: FlinkCollection;
  chainId: chainIdOption;
  dataVesion: TokenInfoVersion;
  tokenIndex: BigNumber;
  tokenSupply: BigNumber;
}) {
  var tokenUri = `tokenUri_test_token_${tokenIndex.toString()}`;

  var data = encodeDataV1(
    author.address,
    tokenUri,
    `fictionName_Token_${tokenIndex.toString()}`,
    `volumeName_Token_${tokenIndex.toString()}`,
    `chapterName_Token_${tokenIndex.toString()}`,
    1,
    1,
    1
  );

  const tokenId = constructTokenId(
    author.address,
    BigNumber.from(2),
    BigNumber.from(2)
  );

  const { msgHash } = generateMessageHash(
    chainId,
    FlinkCollection.address,
    tokenId,
    dataVesion,
    data,
    tokenUri,
    "Test_Token_2"
  );

  var compactSig = await author.signMessage(msgHash);

  const nonce = await nonceGenerator(author.address);

  await FlinkCollection.initializeTokenInfoPermit({
    tokenId,
    version: dataVesion,
    data,
    tokenUri,
    nonce,
    signature: compactSig,
  });

  return { version: dataVesion, data, initialized: true };
}
