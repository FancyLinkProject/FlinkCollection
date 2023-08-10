import { ethers } from "hardhat";
import hre from "hardhat";
import {
  flinkCollection,
  seaportAddress14,
  seaportAddress15,
  seaportOrderType,
} from "../constants/constants";
const fs = require("fs");
import { OrderComponents } from "../types/type";
import { Wallet, Contract, BigNumber } from "ethers";
import {
  calculateOrderHash,
  getItemNative,
  getItem1155,
  constructOrderComponents,
  getBasicOrderParameters,
} from "../utils/utils";
import { toBN, toKey } from "../utils/encoding";
import { parseUnits } from "ethers/lib/utils";
import { chainIdOption, OfferItem, ConsiderationItem, CriteriaResolver } from "../types/type";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { constructTokenId } from "../utils/tokenIdentifier";
import {
  encodeDataV1,
  generateMessageHash,
  generateSingleTokenInitializeInfoVersion1,
  nonceGenerator,
} from "../utils/tokenInitializationPermit";
import { generateTokenInfoVersion1 } from "../utils/tokenInitializationPermit";
import { TokenInfoVersion } from "./constants";
import { Ownable } from "../typechain-types";
import { Seaport } from "../typechain-types/Seaport";

// Returns signature
const signOrder = async (
  orderComponents: OrderComponents,
  signer: Wallet | Contract,
  chainId: chainIdOption
) => {
  const domainData = {
    name: "Seaport",
    version: "1.5",
    chainId: chainId,
    verifyingContract: seaportAddress15,
  };

  const signature = await signer._signTypedData(domainData, seaportOrderType, orderComponents);

  return signature;
};

interface OrderData {
  chainId: chainIdOption;
  orderType: 0 | 1 | 2 | 3;
  rawNftIdentifierOrCriteria: string;
  nftAmount: number;
  price: number;
  royaltyPercent: number;
  platformServiceFeePercent: number;
  offerer: SignerWithAddress;
  buyer: SignerWithAddress;
  author: SignerWithAddress;
  platformAddress: string;
  flinkContractAddress: string;
  zone: string;
}

async function generateBatchTestListData(data: OrderData, seaportContract: Seaport) {
  const {
    chainId,
    orderType,
    rawNftIdentifierOrCriteria,
    nftAmount,
    price,
    royaltyPercent,
    platformServiceFeePercent,
    offerer,
    buyer,
    author,
    platformAddress,
    flinkContractAddress,
    zone,
  } = data;

  //从seaport合约获取counter
  // const counter: BigNumber = await marketplaceContract.getCounter(offerer.address);
  const counter: BigNumber = BigNumber.from(0);

  const nftIdentifierOrCriteria = BigNumber.from(rawNftIdentifierOrCriteria);

  //订单时间有效期,单位为秒
  const timespan = 60 * 60 * 24 * 90;

  //   构建offer，使用ERC1155，因为我们平台的Flink collection合约使用的是ERC1155
  const offer = [
    getItem1155({
      token: flinkContractAddress,
      identifierOrCriteria: nftIdentifierOrCriteria,
      startAmount: nftAmount,
      endAmount: nftAmount,
    }),
  ];

  //   版税
  const royalty = (price * royaltyPercent).toFixed(15);
  //   平台服务费
  const platformServiceFee = (price * platformServiceFeePercent).toFixed(15);
  //   买家所得
  const buyerPayment = (price - Number(royalty) - Number(platformServiceFee)).toFixed(15);

  //  构建consideration
  const consideration = [
    // 支付给买家的
    getItemNative({
      startAmount: parseUnits(buyerPayment.toString(), 18),
      endAmount: parseUnits(buyerPayment.toString(), 18),
      recipient: offerer.address,
    }),
    // 支付给作者的版税
    getItemNative({
      startAmount: parseUnits(royalty, 18),
      endAmount: parseUnits(royalty, 18),
      recipient: author.address,
    }),
    // 支付给平台的服务费
    getItemNative({
      startAmount: parseUnits(platformServiceFee, 18),
      endAmount: parseUnits(platformServiceFee, 18),
      recipient: platformAddress,
    }),
  ];

  const startTime = Math.floor(new Date().getTime() / 1000);
  const endTime = startTime + timespan;

  //   get signed order
  const { orderHash, value, orderParameters, orderComponents } = await constructOrderComponents({
    offerer: offerer as any,
    offer,
    consideration,
    orderType: orderType,
    zone,
    counter,
    startTime,
    endTime,
  });

  //   签署orderComponents
  const flatSig = await signOrder(orderComponents, offerer as any, chainId);

  //   构建order
  const order = {
    parameters: orderParameters,
    signature: flatSig,
    //   numerator: 1, // only used for advanced orders
    //   denominator: 1, // only used for advanced orders
    //   extraData: "0x", // only used for advanced orders
  };

  return { order, value };
}

async function generateTokenInfoInitializationData(
  Author: SignerWithAddress,
  flinkCollectionAddress: string,
  tokenId: BigNumber,
  chainId: chainIdOption,
  dataVersion: number,

  tokenUri: string,
  fictionName: string,
  volumeName: string,
  chapterName: string,
  volumeNo: number,
  chapterNo: number,
  wordsAmount: number
) {
  var data = encodeDataV1(
    Author.address,
    fictionName,
    volumeName,
    chapterName,
    volumeNo,
    chapterNo
  );
  const nonce = await nonceGenerator(Author.address);

  const { msgHash } = generateMessageHash(
    chainId,
    flinkCollectionAddress,
    tokenId,
    dataVersion,
    data,
    tokenUri,
    nonce
  );

  var compactSig = await Author.signMessage(msgHash);

  const tokenInfoInitializationData = generateTokenInfoVersion1(
    tokenId,
    dataVersion,
    data,
    tokenUri,
    nonce,
    compactSig
  );

  return tokenInfoInitializationData;
}

async function main() {
  const [FancyLinkDeployer, FancyLinkDev2, account_3, account_4] = await hre.ethers.getSigners();

  // 获取seaport abi，构建seaport合约对象
  let seaportAbiRawdata = await fs.readFileSync("./abi/seaport.json");
  let seaportAbi = JSON.parse(seaportAbiRawdata);
  const seaportContract = (await ethers.getContractAt(
    seaportAbi,
    seaportAddress15
  )) as any as Seaport;

  const flinkContractAddress = "0x4345983dd8E5f7AF8106964F644E1D9f1f8eDfC6";
  const zone = "0x86093ac33176D4CdEE2981269913c29a2b6c0BF9";

  const platformAddress = "0x176cc044b7f181C509A1d145E6DA2877B6c88162";
  const chainId = 80001;
  const rawNftIdentifierOrCriteria = constructTokenId(
    FancyLinkDev2.address,
    BigNumber.from(2),
    BigNumber.from(1)
  ).toString();

  console.log({rawNftIdentifierOrCriteria})
  process.exit()

  const data: OrderData = {
    chainId,
    orderType: 3,
    rawNftIdentifierOrCriteria,
    nftAmount: 1,
    price: 0.0001,
    royaltyPercent: 0.06,
    platformServiceFeePercent: 0.01,
    offerer: FancyLinkDev2,
    buyer: FancyLinkDev2,
    author: FancyLinkDev2,
    platformAddress,
    flinkContractAddress,
    zone,
  };

  const { order, value } = await generateBatchTestListData(data, seaportContract);

  const fictionName = "Fancy";
  const volumeName = "Imagination";
  const chapterName = "Challenge";
  const volumeNo = 3;
  const chapterNo = 5;
  const wordsAmount = 12345;
  const tokenUri = "https://www.fancylink/nft/metadata/0x1/";

  //generate token initialization data
  const nftInitializationData = await generateTokenInfoInitializationData(
    FancyLinkDev2,
    flinkContractAddress,
    BigNumber.from(rawNftIdentifierOrCriteria),
    chainId,
    TokenInfoVersion.V1,
    tokenUri,
    fictionName,
    volumeName,
    chapterName,
    volumeNo,
    chapterNo,
    wordsAmount
  );

  const extraData = generateSingleTokenInitializeInfoVersion1(nftInitializationData, []);

  const newOrder = Object.assign(order, { numerator: 1, denominator: 1, extraData: extraData });

  fs.writeFile("generatedOrder.json", JSON.stringify(order), function (err: any) {
    if (err) throw err;
    console.log("complete");
  });

  const balance = await account_3.getBalance();

  //  fullfill using signed order
  const tx = await seaportContract
    .connect(account_3)
    .fulfillAdvancedOrder(newOrder, [], toKey(0), FancyLinkDev2.address, {
      value,
      gasLimit: 1000000,
    });

  console.log({ tx });
}

main();
