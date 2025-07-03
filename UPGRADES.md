# 🔄 Contratos Upgradeables - Guía Completa

Esta guía explica cómo usar la arquitectura upgradeable completa implementada en el proyecto de NFTs musicales de Tuneport.

## 📋 Resumen

Se ha implementado un patrón de proxy upgradeable usando **OpenZeppelin Upgrades** con el estándar **UUPS** (Universal Upgradeable Proxy Standard) que permite:

- ✅ Actualizar la lógica de los contratos sin perder datos
- ✅ Mantener las mismas direcciones de contrato
- ✅ Corregir bugs y agregar nuevas funcionalidades
- ✅ Mejor eficiencia en gas comparado con otros patrones
- ✅ **Portabilidad total** - Los artistas pueden usar sus contratos en cualquier plataforma

## 🏗️ Arquitectura Completa

### Contratos Upgradeables Desplegados:

#### **1. Factories (Usados por el Frontend)**

**`MusicNFTFactoryUpgradeable.sol`**

- Factory upgradeable que crea colecciones upgradeables usando proxies
- **Proxy Address**: `0xAD6474aB644B97A4B82C2128921c32aF69392B15` (Base Sepolia)
- **Implementation**: `0xC8577Fd1d613e372FB0682eFf33b5Cfa20afeAf6`

**`RevenueShareFactoryUpgradeable.sol`**

- Factory upgradeable para crear contratos de distribución de ingresos upgradeables
- **Proxy Address**: `0x60CD9B009799636f59367E4C06b5Ad95Ce1E218F` (Base Sepolia)
- **Implementation**: `0x3cBA4cc0212450144A5C13778B11d8F210d634E2`

#### **2. Implementation Templates**

**`MusicCollectionUpgradeable.sol`**

- Versión upgradeable del contrato de colección ERC1155
- **Implementation Address**: `0xF8BE24aA04Bb95C5038F8dc1dAE28c0BD191cC36`
- Usado como template para todas las colecciones creadas por el factory

**`RevenueShareUpgradeable.sol`**

- Versión upgradeable del contrato de distribución de ingresos para NFT musicales
- **Implementation Address**: `0x4151C8c01Eec4426179231AAfB37dCa81Ed19C14`
- Usado como template para todos los revenue shares creados por el factory

### Patrones Implementados:

- **UUPS Proxy Pattern** - Para upgrades eficientes y gas-optimizados
- **Factory + Proxy Pattern** - Para crear múltiples instancias upgradeables
- **Initializer Pattern** - En lugar de constructores para compatibilidad con proxies

## 🚀 Instalación y Setup

### 1. Instalar Dependencias

```bash
npm install
```

Las dependencias incluyen:

- `@openzeppelin/contracts-upgradeable` - Contratos upgradeables
- `@openzeppelin/hardhat-upgrades` - Plugin de Hardhat para upgrades
- `hardhat` - Framework de desarrollo

### 2. Compilar Contratos

```bash
npm run compile
```

## 📦 Deployment

### Deployment Inicial Completo

Para desplegar todos los contratos upgradeables:

```bash
# Red local
npx hardhat run scripts/deploy-all-upgradeable.js

# Testnet (Base Sepolia) - Ya desplegado
npx hardhat run scripts/deploy-all-upgradeable.js --network baseSepolia
```

Esto crea **automáticamente**:

1. **MusicCollectionUpgradeable Implementation**
2. **MusicNFTFactoryUpgradeable Proxy + Implementation**
3. **RevenueShareUpgradeable Implementation**
4. **RevenueShareFactoryUpgradeable Proxy + Implementation**
5. **Archivos de configuración**: `deployment-upgradeable-complete.json` y `frontend-config.json`

### Resultado del Deployment (Base Sepolia)

```
🎵 MUSIC NFT CONTRACTS:
  🏭 Factory Proxy: 0xAD6474aB644B97A4B82C2128921c32aF69392B15
  🔧 Factory Implementation: 0xC8577Fd1d613e372FB0682eFf33b5Cfa20afeAf6
  📜 Collection Implementation: 0xF8BE24aA04Bb95C5038F8dc1dAE28c0BD191cC36

💰 REVENUE SHARE CONTRACTS:
  🏭 Factory Proxy: 0x60CD9B009799636f59367E4C06b5Ad95Ce1E218F
  🔧 Factory Implementation: 0x3cBA4cc0212450144A5C13778B11d8F210d634E2
  📜 RevenueShare Implementation: 0x4151C8c01Eec4426179231AAfB37dCa81Ed19C14
```

## 🔄 Realizando Upgrades

### Upgrade Completo (Todos los Contratos)

```bash
# Red local
npx hardhat run scripts/upgrade-all-contracts.js

# Testnet (Base Sepolia)
npx hardhat run scripts/upgrade-all-contracts.js --network baseSepolia
```

Este script actualiza:

- ✅ **MusicNFTFactoryUpgradeable** (proxy permanece igual)
- ✅ **RevenueShareFactoryUpgradeable** (proxy permanece igual)
- ✅ **Implementations** (direcciones pueden cambiar)

### Upgrade Selectivo

```bash
# Solo actualizar implementations (recomendado)
npx hardhat run scripts/upgrade-all-contracts.js --network baseSepolia --implementations-only

# Actualizar todo incluyendo factories
npx hardhat run scripts/upgrade-all-contracts.js --network baseSepolia --full-upgrade
```

## 🎯 Uso de los Contratos

### Frontend: Crear una Nueva Colección

```javascript
// Usar la dirección del factory proxy (nunca cambia)
const factory = await ethers.getContractAt(
  "MusicNFTFactoryUpgradeable",
  "0xAD6474aB644B97A4B82C2128921c32aF69392B15" // Base Sepolia
);

const tx = await factory.createCollection(
  "Mi Álbum 2024",                          // name
  "ALBUM24",                                // symbol
  "https://api.midominio.com/metadata/",    // baseURI
  "Metadatos del álbum completo",           // collection metadata
  Math.floor(Date.now() / 1000),           // Start date (ahora)
  Math.floor(Date.now() / 1000) + 86400*30, // End date (30 días)
  "0x0000000000000000000000000000000000000000", // ETH nativo
  "0xArtistAddress...",                     // royalty receiver
  1000,                                     // 10% royalty (1000/10000)
  "0xArtistAddress...",                     // collection owner
  "0xRevenueShareAddress..."                // revenue share contract
);

// Obtener la dirección de la nueva colección del evento
const receipt = await tx.wait();
const event = receipt.logs.find(log => /* buscar CollectionCreated */);
const collectionAddress = event.args.collection;
```

### Frontend: Configurar Revenue Share

```javascript
// Crear revenue share para el artista
const revenueFactory = await ethers.getContractAt(
  "RevenueShareFactoryUpgradeable",
  "0x60CD9B009799636f59367E4C06b5Ad95Ce1E218F" // Base Sepolia
);

const tx = await revenueFactory.createRevenueShare(
  "0xArtistAddress...",     // artist (owner)
  "Revenue Share Album 2024", // name
  "Distribución de ingresos para el álbum 2024" // description
);

const receipt = await tx.wait();
const revenueShareAddress = /* extraer del evento */;
```

### Interactuar con una Colección (Cualquier Plataforma)

```javascript
// Los artistas pueden usar esto en su propia web
const collection = await ethers.getContractAt(
  "MusicCollectionUpgradeable",
  collectionAddress // Dirección obtenida del factory
);

// Mint con ETH (funciona desde cualquier plataforma)
await collection.mint(
  "0xBuyerAddress...", // to
  1, // tokenId
  5, // cantidad
  ethers.parseEther("0.1"), // precio por token
  "https://metadata.uri", // token metadata
  { value: ethers.parseEther("0.5") } // 5 tokens × 0.1 ETH
);

// Mint con ERC20
await collection.mintWithERC20(
  "0xBuyerAddress...", // to
  1, // tokenId
  5, // cantidad
  ethers.parseUnits("50", 6), // precio en USDC (6 decimales)
  "0xUSDCAddress...", // token address
  "https://metadata.uri" // token metadata
);
```

## 🌐 Portabilidad para Artistas

### Uso Multi-Plataforma

Una vez que un artista crea su colección, puede usarla en **cualquier lugar**:

#### **1. En su propia página web:**

```javascript
// Ejemplo: www.artista.com
const artistCollection = new ethers.Contract(
  "0x123...abc", // Su dirección de colección
  MusicCollectionABI,
  signer
);

// Mint directo desde su web
await artistCollection.mint(...);
```

#### **2. En otros marketplaces:**

- **OpenSea**: Automáticamente detecta ERC1155 + royalties (ERC2981)
- **Rarible**: Soporte completo para colecciones custom
- **Foundation**: Integración directa

#### **3. En otras plataformas musicales:**

```javascript
// Ejemplo: Async Art, Catalog, Sound.xyz
const collection = new ethers.Contract(artistCollectionAddress, ABI, signer);
// Funciona automáticamente con revenue splits
```

### Revenue Sharing Universal

Los splits funcionan **automáticamente** sin importar dónde se venda:

```javascript
// Desde cualquier plataforma
const revenueShare = new ethers.Contract(revenueShareAddress, ABI, signer);

// Ver configuración actual
const splits = await revenueShare.getMintSplits(collectionAddress, tokenId);

// Los pagos se distribuyen automáticamente en cada mint/venta
```

## ⚠️ Consideraciones de Seguridad

### 1. Autorización de Upgrades

Solo el **owner** puede autorizar upgrades gracias a la función `_authorizeUpgrade()`:

```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
```

### 2. Storage Layout (CRÍTICO)

**NUNCA** modifiques el orden de las variables de estado existentes:

```solidity
// ✅ CORRECTO - Agregar nuevas variables al final
contract MusicCollectionUpgradeableV2 {
    // ... todas las variables existentes en el mismo orden ...

    // Nuevas variables al final
    mapping(uint256 => bool) public newFeature;
    uint256 public newCounter;
}

// ❌ INCORRECTO - Cambiar orden o insertar en el medio
contract MusicCollectionUpgradeableV2 {
    uint256 public newVariable; // ❌ Insertado al inicio
    string public name;         // ❌ Esto rompería el storage
    // ... resto de variables
}
```

### 3. Inicialización

Usa **siempre** `initialize()` en lugar de constructores:

```solidity
function initialize(
    string memory _name,
    // ... otros parámetros
) public initializer {
    __ERC1155_init(_baseURI);
    __ERC1155Supply_init();
    __ERC2981_init();
    __Ownable_init(initialOwner);
    __ReentrancyGuard_init();
    __UUPSUpgradeable_init();

    // Inicialización custom
    name = _name;
    // ...
}
```

## 🔍 Verificación y Monitoreo

### Verificar Versiones Actuales

```javascript
// Verificar versión del MusicNFTFactory
const factory = await ethers.getContractAt(
  "MusicNFTFactoryUpgradeable",
  "0xAD6474aB644B97A4B82C2128921c32aF69392B15"
);

const version = await factory.version();
console.log("Factory version:", version);

// Verificar versión del RevenueShareFactory
const revenueFactory = await ethers.getContractAt(
  "RevenueShareFactoryUpgradeable",
  "0x60CD9B009799636f59367E4C06b5Ad95Ce1E218F"
);

const revenueVersion = await revenueFactory.version();
console.log("Revenue factory version:", revenueVersion);
```

### Verificar Direcciones de Implementation

```javascript
const { upgrades } = require("hardhat");

// Dirección de implementación actual del factory
const factoryImpl = await upgrades.erc1967.getImplementationAddress(
  "0xAD6474aB644B97A4B82C2128921c32aF69392B15"
);

// Dirección de implementación de colecciones
const collectionImpl = await factory.collectionImplementation();

// Dirección de implementación de revenue shares
const revenueImpl = await revenueFactory.revenueShareImplementation();

console.log({
  factoryImpl,
  collectionImpl,
  revenueImpl,
});
```

## 📊 Comparación: Original vs Upgradeable

| Aspecto            | Contratos Originales   | Contratos Upgradeables       |
| ------------------ | ---------------------- | ---------------------------- |
| **Flexibilidad**   | ❌ Sin upgrades        | ✅ Upgrades sin perder datos |
| **Direcciones**    | ❌ Cambian en redeploy | ✅ Permanentes               |
| **Gas Deployment** | ✅ Menor inicial       | ⚠️ Ligeramente mayor         |
| **Gas Uso**        | ✅ Directo             | ⚠️ Proxy overhead mínimo     |
| **Compatibilidad** | ✅ Estándar            | ✅ Estándar + upgradeable    |
| **Portabilidad**   | ✅ Total               | ✅ Total + mejor             |
| **Mantenimiento**  | ❌ Redeploy completo   | ✅ Upgrade seamless          |

## 🚀 Roadmap de Upgrades

### Versión Actual (v1.0.0)

- ✅ Arquitectura upgradeable completa
- ✅ Factory + Proxy pattern
- ✅ Revenue sharing automático
- ✅ Portabilidad total

### Próximas Versiones

**v1.1.0 (Próximo)**

- 🔜 Optimizaciones de gas
- 🔜 Funciones adicionales de metadata
- 🔜 Mejoras en revenue sharing

**v1.2.0**

- 🔜 Integración con streaming
- 🔜 Funciones avanzadas de remix
- 🔜 Multi-chain support

## 🔗 Enlaces Útiles

- **OpenZeppelin Upgrades Docs**: https://docs.openzeppelin.com/upgrades-plugins/
- **UUPS Standard**: https://eips.ethereum.org/EIPS/eip-1822
- **Base Sepolia Explorer**: https://sepolia.basescan.org/

## 📞 Soporte

Para consultas sobre upgrades:

1. **Revisar documentación** de OpenZeppelin Upgrades
2. **Verificar storage layout** antes de cualquier upgrade
3. **Testear en red local** antes de producción
4. **Consultar con el equipo** para upgrades complejos

---

**La arquitectura upgradeable de Tuneport permite evolución continua manteniendo la soberanía de los artistas** 🎵🚀
