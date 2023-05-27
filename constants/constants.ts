export const seaportAddress = "0x00000000006c3852cbef3e08e8df289169ede581";
export const seaportAddress14 = "0x00000000000001ad428e4906aE43D8F9852d0dD6";

// seaport 1.1's domainSeparator
export const domainSeparatorDict = {
  1: "0x712fdde1f147adcbb0fabb1aeb9c2d317530a46d266db095bc40c606fe94f0c2", //ethereum mainnet
  5: "0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e", //ethereum goerli testnet
  137: "0x9b0651fb24301f8cb24693ccaf43dc1cb69134121e8741c4159b3e1dd40c457c", // polygon mainnet
  8001: "0x46c662e63a925f0cd2f82ad7a8907b4d6baadf339e04063513313948cdfbd43c", //polygon mumbai testnet
};

// seaport 1.4's domainSeparator
export const domainSeparatorDict14 = {
  1: "0x276bc64a43ff20d362b6c982bc21d1f83716496363478990aa0bbaa99044923a", //ethereum mainnet
  5: "0xf61f0f8372e08211231070ae70607a57930b2f548b5dea74cc5804c8e0d163f0", //ethereum goerli testnet
  137: "0x8fa7ec135716ef1a3dc97dca405935ed9c2361b278f0ffe6056cdf3be167565c", // polygon mainnet
  8001: "0x8ee1ced59c6e0e4c0bba6f4563aea952b64f7c2b5acf51e978ac05349054f6fe", //polygon mumbai testnet
};

export const flinkCollection = {
  1: "", //ethereum mainnet
  5: "0xc46422A3d87D36d2B53f694BD8B33cF2Abfae4C8", //ethereum goerli testnet
  137: "", // polygon mainnet
  80001: "0x3ee2c0C4a17cBbC7ae2297F25241cfA1bF3D384E", //polygon mumbai testnet
};

export const wethAddress = {
  5: "0xb4fbf271143f4fbf7b91a5ded31805e42b2208d6",
  1: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
};

export const wMaticAddress = {
  137: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
  80001: "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
};

export const seaportOrderType = {
  OrderComponents: [
    { name: "offerer", type: "address" },
    { name: "zone", type: "address" },
    { name: "offer", type: "OfferItem[]" },
    { name: "consideration", type: "ConsiderationItem[]" },
    { name: "orderType", type: "uint8" },
    { name: "startTime", type: "uint256" },
    { name: "endTime", type: "uint256" },
    { name: "zoneHash", type: "bytes32" },
    { name: "salt", type: "uint256" },
    { name: "conduitKey", type: "bytes32" },
    { name: "counter", type: "uint256" },
  ],
  OfferItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
  ],
  ConsiderationItem: [
    { name: "itemType", type: "uint8" },
    { name: "token", type: "address" },
    { name: "identifierOrCriteria", type: "uint256" },
    { name: "startAmount", type: "uint256" },
    { name: "endAmount", type: "uint256" },
    { name: "recipient", type: "address" },
  ],
};
