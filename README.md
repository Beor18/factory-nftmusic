# Whitepaper - Tuneport

## 🎵 Introduction

Tuneport is a Web3 music platform where musicians upload their songs, can distribute revenue with or without collaborators, and sell to their fans, preserving their creative sovereignty. Tuneport eliminates intermediaries, improves revenue, and enables experiences like remixes, collectible fragments, and tokenized playlists.

## 🧭 Motivation & Vision

Our goal is to establish the technical and philosophical foundation of the blockchain music ecosystem. We are defining the standard for how Web3 music platforms should balance innovation with usability, sovereignty with accessibility, and profitability with artistic integrity.

Tuneport serves as both a functional platform and an open blueprint—demonstrating that music NFTs can be more than mere speculation, that streaming can coexist with ownership, and that complex revenue distribution can execute frictionlessly on the blockchain in a scalable manner.

We are charting the path from Argentina to the world, proving that the future of music is not only decentralized—it is artist-centered, fan-focused, and built on scalable infrastructure.

## ✨ Problem

- Artists earn pennies per thousands of plays.
- They cannot monetize remixes or playlists.
- Current Web3 platforms lack streaming, good UX, and scalability.

## 💡 Tuneport Solution

- On-chain splits.
- Interactive streaming: minting of fragments, remixes, playlists.
- Frictionless onboarding (email or wallet thanks to Privy).
- Uninterrupted streaming on mobile and web.
- Modular architecture deployed on Base with gasless minting.
- **Upgradeable contracts** - Artists' contracts can be improved without losing data or changing addresses.
- If Tuneport doesn't exist, the artist can continue using the smart contracts with complete freedom and without intermediaries.

## 🚀 Smart Contract Architecture (Upgradeable)

### **Factory Contracts (Used by Frontend)**

**MusicNFTFactoryUpgradeable.sol**

- Creates upgradeable music collections using proxy pattern
- Configurable mint start/end dates, payments, and royalties
- Deployed at: `0xAD6474aB644B97A4B82C2128921c32aF69392B15` (Base Sepolia)

**RevenueShareFactoryUpgradeable.sol**

- Creates upgradeable revenue distribution contracts
- Manager and artist role system
- Deployed at: `0x60CD9B009799636f59367E4C06b5Ad95Ce1E218F` (Base Sepolia)

### **Implementation Contracts (Templates)**

**MusicCollectionUpgradeable.sol**

- Custom upgradeable ERC1155 implementation for audio
- Individual metadata per track or fragment
- Integration with RevenueShare for automatic payments
- Implementation at: `0xF8BE24aA04Bb95C5038F8dc1dAE28c0BD191cC36`

**RevenueShareUpgradeable.sol**

- Configurable splits for primary and secondary revenue
- Support for inheritance in remixes and playlists
- Cascade tracking and manager roles
- Payments in ETH or ERC20 tokens
- Implementation at: `0x4151C8c01Eec4426179231AAfB37dCa81Ed19C14`

### **Key Features**

- **Upgradeable Architecture**: UUPS proxy pattern for future improvements
- **Artist Sovereignty**: Each artist owns their contracts completely
- **Platform Portability**: Artists can use their contracts on any platform
- **Revenue Automation**: Automatic payment distribution on every transaction
- **Remix Inheritance**: Remixes automatically share revenue with original artists

## 🔄 Operational Flow

1. **Artist creates collection** via MusicNFTFactory
2. **Configures royalties, dates, and splits** through RevenueShare
3. **Users mint, remix, or create playlists** from any platform
4. **RevenueShare distributes payments** according to configured logic
5. **Remixes/playlists automatically inherit** revenue to original artists

## ✨ Differentiators

- **Truly Portable NFTs**: Work on any platform, not vendor locked
- **Remixable NFTs**: Built-in remix functionality with revenue sharing
- **Tokenized playlists**: Playlists as tradeable NFTs
- **Albums, collective drops, and singles** as upgradeable NFT collections
- **Streaming integration** (without broken crypto UX)
- **Gasless integration** with Privy (smart wallets without seed phrase)
- **Monetization from every interaction**

## 🌐 Artist Independence

### **Multi-Platform Usage**

Once an artist creates their contracts through Tuneport, they own them forever and can use them on:

- **Other NFT Marketplaces**: OpenSea, Rarible, Foundation
- **Their own website**: Direct minting and sales
- **Other music platforms**: Async Art, Catalog, Sound.xyz
- **Mobile apps**: Any dApp can integrate their contracts

### **Revenue Sharing Anywhere**

Revenue distribution works automatically regardless of where the NFT is sold:

```javascript
// Artists can mint from their own website
const artistCollection = new ethers.Contract(
  "0x123...abc", // Their collection address from Tuneport factory
  ERC1155_ABI,
  signer
);

await artistCollection.mint(...); // Revenue splits work automatically
```

## Project Structure

```
.
├── contracts/                           # Smart contracts
│   ├── interfaces/                      # Interfaces and abstract contracts
│   │   ├── IMusicCollection.sol         # Interface for music collections
│   │   ├── IMusicNFTFactory.sol         # Interface for main factory
│   │   └── IRevenueShare.sol            # Interface for revenue distribution
│   ├── MusicCollectionUpgradeable.sol   # Upgradeable ERC1155 NFT implementation
│   ├── MusicNFTFactoryUpgradeable.sol   # Upgradeable factory to create collections
│   ├── RevenueShareUpgradeable.sol      # Upgradeable revenue distribution system
│   ├── RevenueShareFactoryUpgradeable.sol # Upgradeable factory for revenue shares
│   └── legacy/                          # Original non-upgradeable contracts (backup)
│       ├── MusicCollection.sol          # Original ERC1155 implementation
│       ├── MusicNFTFactory.sol          # Original factory
│       ├── RevenueShare.sol             # Original revenue system
│       └── RevenueShareFactory.sol      # Original revenue factory
│
├── scripts/                             # Deployment scripts and utilities
│   ├── utils/                           # Helper functions for scripts
│   │   └── deploy-helpers.js            # Deployment utilities
│   ├── deploy-all-upgradeable.js        # Complete upgradeable platform deployment
│   └── upgrade-all-contracts.js         # Upgrade all contracts
│
├── test/                                # Automated tests
│   └── [test files]                     # Contract tests
│
├── .openzeppelin/                       # OpenZeppelin upgrades data
├── deployment-upgradeable-complete.json # Complete deployment info
├── frontend-config.json                 # Frontend configuration
├── UPGRADES.md                          # Detailed upgrades documentation
├── hardhat.config.js                    # Hardhat configuration
└── README.md                            # This file
```

## Installation

```bash
npm install
```

### Dependencies

- `@openzeppelin/contracts-upgradeable` - Upgradeable contract implementations
- `@openzeppelin/hardhat-upgrades` - Hardhat plugin for proxy upgrades
- `hardhat` - Development framework

## Compilation

```bash
npm run compile
```

## Testing

```bash
npm run test
```

## Available Scripts

### Development

- `npm run compile` - Compiles contracts
- `npm run test` - Runs tests
- `npm run coverage` - Generates coverage report
- `npm run clean` - Cleans generated files
- `npm run lint` - Formats Solidity code

### Deployment (Upgradeable)

```bash
# Deploy complete upgradeable platform
npx hardhat run scripts/deploy-all-upgradeable.js --network baseSepolia

# Upgrade all contracts
npx hardhat run scripts/upgrade-all-contracts.js --network baseSepolia
```

## 📍 Live Deployments

### **Base Sepolia Testnet (Current)**

#### **Frontend Integration Addresses:**

```javascript
// Use these addresses in your frontend
const MUSIC_NFT_FACTORY = "0xAD6474aB644B97A4B82C2128921c32aF69392B15";
const REVENUE_SHARE_FACTORY = "0x60CD9B009799636f59367E4C06b5Ad95Ce1E218F";
```

#### **Complete Contract Map:**

- **MusicNFTFactory (Proxy)**: `0xAD6474aB644B97A4B82C2128921c32aF69392B15`
- **RevenueShareFactory (Proxy)**: `0x60CD9B009799636f59367E4C06b5Ad95Ce1E218F`
- **MusicCollection Implementation**: `0xF8BE24aA04Bb95C5038F8dc1dAE28c0BD191cC36`
- **RevenueShare Implementation**: `0x4151C8c01Eec4426179231AAfB37dCa81Ed19C14`
- **Factory Implementations**: Managed automatically by OpenZeppelin

## Network Configuration

The project is configured to deploy on:

- **Base Sepolia** (testnet): Chain ID 84532 ✅ **Currently Deployed**
- **Hardhat Local Network**: For local development

## Environment Variables

Create a `.env` file with:

```bash
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_basescan_api_key
```

## 🔄 Upgrade Management

### **Performing Upgrades**

The platform supports seamless upgrades without data loss:

```bash
# Upgrade all contracts maintaining same addresses
npx hardhat run scripts/upgrade-all-contracts.js --network baseSepolia
```

### **Artist Contract Independence**

Once created, each artist's collection operates independently:

- **Permanent ownership** - Artist is the owner forever
- **Multi-platform compatibility** - Works on any NFT marketplace
- **Automatic revenue distribution** - Functions regardless of sale platform
- **Upgradeable benefits** - Improvements without address changes

## 🎵 Usage Examples

### **Creating a Collection (Frontend)**

```javascript
const musicFactory = new ethers.Contract(
  "0xAD6474aB644B97A4B82C2128921c32aF69392B15",
  MusicNFTFactoryABI,
  signer
);

const tx = await musicFactory.createCollection(
  "Mi Album 2024", // name
  "ALBUM24", // symbol
  "https://api.artist.com/", // baseURI
  "Album metadata", // collection metadata
  startTimestamp, // mint start
  endTimestamp, // mint end
  ethers.ZeroAddress, // ETH payments
  artistAddress, // royalty receiver
  1000, // 10% royalties
  artistAddress, // collection owner
  revenueShareAddress // revenue distribution
);
```

### **Minting from Artist's Own Website**

```javascript
// Artist can integrate their collection anywhere
const artistCollection = new ethers.Contract(
  collectionAddress, // From createCollection result
  MusicCollectionABI,
  signer
);

await artistCollection.mint(
  buyerAddress,
  tokenId,
  quantity,
  pricePerToken,
  metadata,
  { value: totalCost }
);
```

## 🌎 Next Steps

- **Mainnet Deployment** - Launch on Base mainnet
- **Additional Network Support** - Polygon, Arbitrum
- **Advanced Features** - Streaming integration, mobile apps
- **Third-party Integrations** - OpenSea, other marketplaces
- **Developer SDK** - Tools for easy integration

## 🔐 Security

- **Audited OpenZeppelin contracts** as base implementations
- **UUPS upgrade pattern** with owner-only authorization
- **Comprehensive test coverage**
- **Gradual rollout** starting with testnet

## 🌎 Closing

Tuneport is the music platform that combines sovereignty for artists, monetization, and experiences in a scalable, upgradeable architecture.

From Corrientes, Argentina to the world: we are ready for every song to be worth what it deserves, for artists to be sovereign and have fair income, on any platform they choose.

---

**Built with ❤️ for the future of music**
