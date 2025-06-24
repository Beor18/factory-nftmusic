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
- If Tuneport doesn't exist, the artist can continue using the smart contracts with complete freedom and without intermediaries.

## 🚀 Smart Contract Features

MusicNFTFactory.sol

- Creation of music collections with mint start/end dates.
- Minting with ETH or ERC20 tokens.
- Optional: free mint for holders or fans.
- Royalties.

MusicCollection.sol

- Custom ERC1155 implementation for audio.
- Individual IPs per track or fragment.
- Integration with RevenueShare for automatic payments.
- RevenueShare & RevenueShareFactory
- Configurable splits for primary and secondary revenue.
- Support for inheritance in remixes and playlists.
- Cascade tracking.
- Roles for manager, artist, and collaborators.
- Payments in ETH or ERC20.

## 🔄 Operational Flow

- The artist launches a collection.
- Configures royalties, dates, and splits.
- Users mint, remix, or create playlists.
- RevenueShare distributes payments according to logic
- If there are remixes or playlists, part of the revenue is inherited towards the original artist

## ✨ Differentiators

- Remixable NFTs.
- Tokenized playlists.
- Albums, collective drops, and singles as NFT collections
- Streaming (without broken crypto UX).
- Gasless integration with Privy (smart wallets without seed phrase).
- Monetization from every interaction.

## Project Structure

```
.
├── contracts/                    # Smart contracts
│   ├── interfaces/               # Interfaces and abstract contracts
│   │   ├── IMusicCollection.sol  # Interface for music collections
│   │   ├── IMusicNFTFactory.sol  # Interface for main factory
│   │   └── IRevenueShare.sol     # Interface for revenue distribution
│   ├── MusicCollection.sol       # ERC1155 NFT implementation
│   ├── MusicNFTFactory.sol       # Factory to create collections
│   ├── RevenueShare.sol          # Revenue distribution system
│   └── RevenueShareFactory.sol   # Factory to create distributors
│
├── scripts/                      # Deployment scripts and utilities
│   ├── utils/                    # Helper functions for scripts
│   │   └── deploy-helpers.js     # Deployment utilities
│   ├── deploy.js                 # Main deployment script
│   ├── deploy-revenue-share.js   # Revenue system deployment
│   ├── deploy-all.js             # Complete platform deployment
│   └── create-collection.js      # Create example collection
│
├── test/                         # Automated tests
│   ├── utils/                    # Testing utilities
│   └── MusicNFTFactory.test.js   # Tests for main factory
│
├── .env                          # Environment variables (do not include in git)
├── hardhat.config.js             # Hardhat configuration
└── README.md                     # Project documentation
```

## Installation

```bash
npm install
```

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

### Deployment

- `npm run deploy` - Basic factory deployment
- `npm run deploy:sepolia` - Deploys on Base Sepolia
- `npm run deploy:revenue` - Deploys revenue distribution system
- `npm run deploy:all` - Deploys complete platform

## Network Configuration

The project is configured to deploy on:

- **Base Sepolia** (testnet): Chain ID 84532
- **Hardhat Local Network**: For local development

## Environment Variables

Create a `.env` file with:

```bash
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_basescan_api_key
```

## Next steps...

- AUDIT

## 🌎 Closing

Tuneport is the music platform that combines sovereignty for artists, monetization, and experiences in a scalable architecture.

From Corrientes, Argentina to the world: we are ready for every song to be worth what it deserves, for artists to be sovereign and have fair income.
