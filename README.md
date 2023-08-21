# FancyLink Platform Smart Contract

* [ ] This is the smart contract for the FancyLink, a web3 platform for publishing and reading novels as NFTs. This smart contract is based on opensea's opensea collection.
* [ ] This contract's main contribution is the development of universal lazymint strategy which can convert almost all the transaction types into lazymint form, so the creator will have zero cost to create and earn revenue from their created NFT.

# **What problem is being addressed in FancyLink**

1. **Limited income sources for authors**

**In the **web2**, authors mainly rely on subscriptions, tips, advertising fees, and copyright to generate income. However, in the early stages of a work, these income sources are relatively limited, making it difficult for authors to obtain sufficient financial support and focus solely on creating. Due to a lack of early attention to their works, many authors face the dilemma of insufficient income, making it difficult for them to continue their creative work, and even abandoning their creative career.**

2. **Inadequate return for readers' contributions**

**In the web2, readers read authors' works through free or paid means, and their active participation brings income to the author, such as subscription fees, advertising fees, etc. However, besides spiritual enjoyment, readers do not receive much value in return. Their contributions to the works and authors do not receive an appropriate feedback.**

**Suppose an unknown emerging author creates a work that, due to the author's lack of fame and short length, has yet to attract widespread attention in the early stages. However, a small group of readers who praise the work are willing to support it through paid subscriptions, tips, and recommending it to their friends.**

**Thanks to the support of early readers, the work continues, the plot unfolds, and it gradually becomes more exciting, attracting more fans. Eventually, the author gains reputation and economic benefits from it. However, the earliest readers' generosity was critical to the work's publication, but as a large number of fans emerged, their existence was gradually drowned out.**

**These early supporters, like later readers, enjoyed the spiritual satisfaction brought by the work, but their investment was much greater and had a more significant meaning for the work's survival and growth, yet they did not receive an appropriate return.**

3. **Serious piracy problem**

**As there is no difference between the reading experience of pirated and legitimate readers, both can enjoy the fun brought by the works. Therefore, users' willingness to pay is not strong enough, leading many readers to choose to obtain works on piracy websites rather than subscribe, resulting in a reduction in the author's income and a suppression of their creative enthusiasm.**

4. **Fast-paced works with a lack of diversity**

**In this fast-paced and traffic-oriented era, works that can immediately attract attention can rapidly accumulate traffic and achieve **monetization**. Conversely, works that require time to cultivate are difficult to gain sufficient attention in the early stages, resulting in reduced creative income for authors. Therefore, more and more authors tend to create fast-paced, immediately satisfying works, resulting in an increasingly prominent problem of homogeneity in the form of works, lacking depth and uniqueness.**

# **Future Plan**

1. **Transparent Subscription Revenue: FancyLink offers a unique subscription feature for works, implementing **blockchain** settlement to ensure prompt payment of subscription fees directly to authors. This ensures transparency in fee collection and permanent storage of subscription records on the blockchain, enabling diverse interactions.**
2. **Creation and Sale of Novel Chapter NFTs: Authors can mint each chapter of their novel as an **NFT** on FancyLink's platform, making them tradable and collectible assets. Authors can earn income by selling these novel NFTs, and royalties can be generated from secondary market transactions as the popularity of the work increases.**
3. **Creation and Sale of Novel **Peripheral** NFTs: Authors can also launch NFT peripherals such as character avatars and illustrations, generating primary market sales revenue and additional royalties from the secondary market. Popularity boosts prices and transaction volume, resulting in more royalty income.**
4. **Deep Binding of Authors, Works, and Readers: FancyLink creates a two-way relationship between readers and works through tokenization, allowing readers to benefit from the increasing value of NFTs associated with the works they support. Authors can provide feedback and rewards to early subscribers or purchasers of specific peripherals, encouraging readers to pay for reading and supporting potentially successful works.**
5. **Support for Slow-Burning Works: FancyLink provides a solution for slow-burning works that lack initial popularity. By creating NFT assets and related peripherals, authors can attract readers who prefer higher-risk investments, allowing them to earn income over time and smooth out the revenue curve for slow-burning works.**
6. **Community: FancyLink's blockchain records users' valuable interactions, facilitating connections between like-minded fans. Users can join work communities based on tipping or holding NFTs, fostering easier communication among fans with similar interests.**
7. **Other: In addition to core features, FancyLink is exploring new forms of creation such as fan fiction and co-creation.**

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
