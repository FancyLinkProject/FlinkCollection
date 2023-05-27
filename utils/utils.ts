import { ethers } from "hardhat";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { BigNumber, BigNumberish, Contract, Wallet } from "ethers";
import { randomHex, toBN, toKey } from "./encoding";
import {
  OrderComponents,
  ConsiderationItem,
  OfferItem,
  Order,
  BasicOrderParameters,
  CriteriaResolver,
  chainIdOption,
} from "../types/type";

export const getItemNative = ({
  startAmount,
  endAmount,
  recipient,
}: {
  startAmount: BigNumberish;
  endAmount: BigNumberish;
  recipient?: string;
}) =>
  getOfferOrConsiderationItem(
    0,
    ethers.constants.AddressZero,
    0,
    toBN(startAmount),
    toBN(endAmount),
    recipient
  );

export const getItem20 = ({
  token,
  startAmount,
  endAmount,
  recipient,
}: {
  token: string;
  startAmount: BigNumberish;
  endAmount: BigNumberish;
  recipient?: string;
}) => getOfferOrConsiderationItem(1, token, 0, startAmount, endAmount, recipient);

export const getItem721 = ({
  token,
  identifierOrCriteria,
  startAmount = 1,
  endAmount = 1,
  recipient,
}: {
  token: string;
  identifierOrCriteria: BigNumberish;
  startAmount?: BigNumberish;
  endAmount?: BigNumberish;
  recipient?: string;
}) =>
  getOfferOrConsiderationItem(2, token, identifierOrCriteria, startAmount, endAmount, recipient);

export const getItem1155 = ({
  token,
  identifierOrCriteria,
  startAmount,
  endAmount,
  recipient,
}: {
  token: string;
  identifierOrCriteria: BigNumberish;
  startAmount?: BigNumberish;
  endAmount?: BigNumberish;
  recipient?: string;
}) =>
  getOfferOrConsiderationItem(3, token, identifierOrCriteria, startAmount, endAmount, recipient);

export const getOfferOrConsiderationItem = <RecipientType extends string | undefined = undefined>(
  itemType: number = 0,
  token: string = ethers.constants.AddressZero,
  identifierOrCriteria: BigNumberish = 0,
  startAmount: BigNumberish = 1,
  endAmount: BigNumberish = 1,
  recipient?: RecipientType
): RecipientType extends string ? ConsiderationItem : OfferItem => {
  const offerItem: OfferItem = {
    itemType,
    token,
    identifierOrCriteria: toBN(identifierOrCriteria),
    startAmount: toBN(startAmount),
    endAmount: toBN(endAmount),
  };
  if (typeof recipient === "string") {
    return {
      ...offerItem,
      recipient: recipient as string,
    } as ConsiderationItem;
  }

  return offerItem as any;
};

export const calculateOrderHash = (orderComponents: OrderComponents) => {
  const offerItemTypeString =
    "OfferItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount)";
  const considerationItemTypeString =
    "ConsiderationItem(uint8 itemType,address token,uint256 identifierOrCriteria,uint256 startAmount,uint256 endAmount,address recipient)";
  const orderComponentsPartialTypeString =
    "OrderComponents(address offerer,address zone,OfferItem[] offer,ConsiderationItem[] consideration,uint8 orderType,uint256 startTime,uint256 endTime,bytes32 zoneHash,uint256 salt,bytes32 conduitKey,uint256 counter)";
  const orderTypeString = `${orderComponentsPartialTypeString}${considerationItemTypeString}${offerItemTypeString}`;

  const offerItemTypeHash = keccak256(toUtf8Bytes(offerItemTypeString));
  const considerationItemTypeHash = keccak256(toUtf8Bytes(considerationItemTypeString));
  const orderTypeHash = keccak256(toUtf8Bytes(orderTypeString));

  const offerHash = keccak256(
    "0x" +
      orderComponents.offer
        .map((offerItem) => {
          return keccak256(
            "0x" +
              [
                offerItemTypeHash.slice(2),
                offerItem.itemType.toString().padStart(64, "0"),
                offerItem.token.slice(2).padStart(64, "0"),
                toBN(offerItem.identifierOrCriteria).toHexString().slice(2).padStart(64, "0"),
                toBN(offerItem.startAmount).toHexString().slice(2).padStart(64, "0"),
                toBN(offerItem.endAmount).toHexString().slice(2).padStart(64, "0"),
              ].join("")
          ).slice(2);
        })
        .join("")
  );

  const considerationHash = keccak256(
    "0x" +
      orderComponents.consideration
        .map((considerationItem) => {
          return keccak256(
            "0x" +
              [
                considerationItemTypeHash.slice(2),
                considerationItem.itemType.toString().padStart(64, "0"),
                considerationItem.token.slice(2).padStart(64, "0"),
                toBN(considerationItem.identifierOrCriteria)
                  .toHexString()
                  .slice(2)
                  .padStart(64, "0"),
                toBN(considerationItem.startAmount).toHexString().slice(2).padStart(64, "0"),
                toBN(considerationItem.endAmount).toHexString().slice(2).padStart(64, "0"),
                considerationItem.recipient.slice(2).padStart(64, "0"),
              ].join("")
          ).slice(2);
        })
        .join("")
  );

  const derivedOrderHash = keccak256(
    "0x" +
      [
        orderTypeHash.slice(2),
        orderComponents.offerer.slice(2).padStart(64, "0"),
        orderComponents.zone.slice(2).padStart(64, "0"),
        offerHash.slice(2),
        considerationHash.slice(2),
        orderComponents.orderType.toString().padStart(64, "0"),
        toBN(orderComponents.startTime).toHexString().slice(2).padStart(64, "0"),
        toBN(orderComponents.endTime).toHexString().slice(2).padStart(64, "0"),
        orderComponents.zoneHash.slice(2),
        orderComponents.salt.slice(2).padStart(64, "0"),
        orderComponents.conduitKey.slice(2).padStart(64, "0"),
        toBN(orderComponents.counter).toHexString().slice(2).padStart(64, "0"),
      ].join("")
  );

  return derivedOrderHash;
};

const getOrderHash = async (orderComponents: OrderComponents) => {
  const derivedOrderHash = calculateOrderHash(orderComponents);
  return derivedOrderHash;
};

export async function constructOrderComponents({
  offerer,
  offer,
  consideration,
  orderType = 0,
  zoneHash = ethers.constants.HashZero,
  zone,
  conduitKey = ethers.constants.HashZero,
  counter,
  startTime,
  endTime,
}: {
  offerer: Wallet | Contract;
  //   zone: undefined | string = undefined,
  offer: OfferItem[];
  consideration: ConsiderationItem[];
  orderType?: number;
  criteriaResolvers?: CriteriaResolver[];

  signer?: Wallet;
  zoneHash?: string;
  zone?: string;
  conduitKey?: string;
  extraCheap?: boolean;
  counter: BigNumber;
  startTime: number;
  endTime: number;
}) {
  // 生成salt，整合到订单中，使得订单独一无二
  const salt = randomHex();

  const orderParameters = {
    offerer: offerer.address,
    zone: zone ? zone : ethers.constants.AddressZero,
    offer,
    consideration,
    totalOriginalConsiderationItems: consideration.length,
    orderType,
    zoneHash,
    salt,
    conduitKey,
    startTime,
    endTime,
  };

  const orderComponents = {
    ...orderParameters,
    counter,
  };

  const orderHash = await getOrderHash(orderComponents);

  // How much ether (at most) needs to be supplied when fulfilling the order
  const value = offer
    .map((x) =>
      x.itemType === 0 ? (x.endAmount.gt(x.startAmount) ? x.endAmount : x.startAmount) : toBN(0)
    )
    .reduce((a, b) => a.add(b), toBN(0))
    .add(
      consideration
        .map((x) =>
          x.itemType === 0 ? (x.endAmount.gt(x.startAmount) ? x.endAmount : x.startAmount) : toBN(0)
        )
        .reduce((a, b) => a.add(b), toBN(0))
    );

  return {
    orderHash,
    value,
    orderParameters,
    orderComponents,
  };
}

export const getBasicOrderParameters = (
  basicOrderRouteType: number,
  order: Order,
  fulfillerConduitKey: string | boolean = false,
  tips: { amount: BigNumber; recipient: string }[] = []
): BasicOrderParameters => ({
  offerer: order.parameters.offerer,
  zone: order.parameters.zone,
  basicOrderType: order.parameters.orderType + 4 * basicOrderRouteType,
  offerToken: order.parameters.offer[0].token,
  offerIdentifier: order.parameters.offer[0].identifierOrCriteria,
  offerAmount: order.parameters.offer[0].endAmount,
  considerationToken: order.parameters.consideration[0].token,
  considerationIdentifier: order.parameters.consideration[0].identifierOrCriteria,
  considerationAmount: order.parameters.consideration[0].endAmount,
  startTime: order.parameters.startTime,
  endTime: order.parameters.endTime,
  zoneHash: order.parameters.zoneHash,
  salt: order.parameters.salt,
  totalOriginalAdditionalRecipients: BigNumber.from(order.parameters.consideration.length - 1),
  signature: order.signature,
  offererConduitKey: order.parameters.conduitKey,
  fulfillerConduitKey: toKey(typeof fulfillerConduitKey === "string" ? fulfillerConduitKey : 0),
  additionalRecipients: [
    ...order.parameters.consideration
      .slice(1)
      .map(({ endAmount, recipient }) => ({ amount: endAmount, recipient })),
    ...tips,
  ],
});
