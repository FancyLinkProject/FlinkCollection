import { ethers } from "hardhat";
import hre from "hardhat";
import { seaportAddress14, seaportOrderType } from "../constants";
const fs = require("fs");
import { OrderComponents } from "../../types/type";
import { Wallet, Contract, BigNumber } from "ethers";
import {
  calculateOrderHash,
  getItemNative,
  getItem1155,
  constructOrderComponents,
  getBasicOrderParameters,
} from "../utils/utils";
import { toBN } from "../utils/encodings";
import { parseUnits } from "ethers/lib/utils";
import { chainIdOption, OfferItem, ConsiderationItem, CriteriaResolver } from "../../types/type";

// Returns signature
const signOrder = async (
  orderComponents: OrderComponents,
  signer: Wallet | Contract,
  chainId: chainIdOption
) => {
  const domainData = {
    name: "Seaport",
    version: "1.4",
    chainId: chainId,
    verifyingContract: seaportAddress14,
  };

  const signature = await signer._signTypedData(domainData, seaportOrderType, orderComponents);

  return signature;
};

async function main() {
  const [offerer, buyer, author, platform] = await hre.ethers.getSigners();

  // 获取seaport abi，构建seaport合约对象
  let seaportAbiRawdata = await fs.readFileSync("./scripts/abi/seaport.json");
  let seaportAbi = JSON.parse(seaportAbiRawdata);
  const marketplaceContract = await ethers.getContractAt(seaportAbi, seaportAddress14);

  //从seaport合约获取counter
  const counter: BigNumber = await marketplaceContract.getCounter(offerer.address);

  //   network
  const chainId = 5;

  //   orderType设置为full open
  const orderType = 0;

  //暂时设置为opensea collectio，方便测试
  const nftContractAddress = "0xf4910C763eD4e47A585E2D34baA9A4b611aE448C";

  //   NFT identifierOrCriteria
  const rawNftIdentifierOrCriteria =
    "98582960906101297647857585165543568735250393964476349489107799754160371400705";
  const nftIdentifierOrCriteria = BigNumber.from(rawNftIdentifierOrCriteria);

  //   设置offer item的数量
  const nftAmount = 1;

  //作为consideration的ETH或者MATIC的数量
  const price = 0.05;

  //   版税比例
  const royaltyPercent = 0.05;

  //   平台服务费比例
  const platformServiceFeePercent = 0.025;

  //订单时间有效期,单位为秒
  const timespan = 60 * 60 * 24;

  //   构建offer，使用ERC1155，因为我们平台的Flink collection合约使用的是ERC1155
  const offer = [
    getItem1155({
      token: nftContractAddress,
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
  const buyerPayment = price - Number(royalty) - Number(platformServiceFee);

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
      recipient: platform.address,
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
    marketplaceContract,
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
    numerator: 1, // only used for advanced orders
    denominator: 1, // only used for advanced orders
    extraData: "0x", // only used for advanced orders
  };

  console.log({
    offerer: offerer.address,
    buyer: buyer.address,
    author: author.address,
    platform: platform.address,
  });
  console.log({
    // order: JSON.stringify(order, null, 2),
    orderHash,
    value,
    // orderComponents: JSON.stringify(orderComponents),
  });
  fs.writeFile("order1.4.json", JSON.stringify(order), function (err) {
    if (err) throw err;
    console.log("complete");
  });

  // 购买测试
  //   provide Eth to get offered ERC721
  // const basicOrderParameters = getBasicOrderParameters(
  //   1, // EthForERC1155
  //   order
  // );

  // //  fullfill using signed order
  // const tx = await marketplaceContract.connect(buyer).fulfillBasicOrder(basicOrderParameters, {
  //   value,
  // });
  // console.log('====-166value', value);
  // console.log('====-165tx', tx);
  // console.log({ tx });
}

main();
