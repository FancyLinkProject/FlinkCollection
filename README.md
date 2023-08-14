# FancyLink Platform Smart Contract

[ ]  This is the smart contract for the FancyLink, a web3 platform for publishing and reading novels as NFTs. This smart contract is based on opensea's opensea collection.

## Contracts

The main contracts are:

* `FlinkCollection.sol`: Implements an ERC-1155 compliant NFT collection that contains novels. Supports lazy minting.
* `TokenInitializationZone.sol`: Implements an zone to validate and initialize NFT info specified by

## FlinkCollection

The FlinkCollection.sol contract allows novelists to create novel NFT collections and lazy mint novel NFTs into those collections. It is ERC-1155 compliant.

Key functions:

* `initializeTokenInfoPermit()`: Initialize  Nft info with signed message of the author.

# TokenInitializationZone

The TokenInitializationZone.sol contract implements a zone standard specified by Seaport. It performs as NFT info checker and initializer.

Key functions:

* `validateOrder()`: Initialize Nft info and validate Nft info againse zoneHash with proof.

## Installation

Copy

```
npm install
```

## Testing

Copy

```
npx hardhat test
```

## Deployment

Scripts for deploying to various networks are in the `deploy` folder.

Example:

Copy

```
npx hardhat run scripts/deployContracts --network goerli
```

## Contributing

Pull requests are welcome. Feel free to open an issue first to discuss any major changes.

## License

MIT
