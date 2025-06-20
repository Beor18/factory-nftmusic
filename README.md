# Factory de NFTs ERC1155 para Artistas Musicales

Este proyecto implementa una plataforma completa de NFTs para artistas musicales utilizando el estándar ERC1155. Permite a los artistas crear colecciones de NFTs con soporte para royalties, distribución avanzada de ingresos, múltiples opciones de pago, y gestión de fechas de mint.

## Características Principales

### Factory de NFTs ERC1155

- Factory de ERC1155 para artistas musicales (`MusicNFTFactory`)
- Soporte completo para royalties (ERC2981)
- Mint con ETH nativo o tokens ERC20
- Opción de free mint para propietarios
- Fechas configurables de inicio y fin de mint

### Sistema de Distribución de Ingresos

- **RevenueShare**: Contrato avanzado para distribución automática de ingresos
- **RevenueShareFactory**: Factory para crear contratos de distribución personalizados
- Splits configurables para mint y reventa
- Soporte para herencia en remixes y playlists
- Sistema de roles (propietario/manager) para gestión flexible
- Distribución automática en ETH y tokens ERC20

### Funcionalidades Avanzadas

- Inheritance tracking para remixes y playlists
- Cascade percentages para distribución jerárquica
- Gestión de roles con AccessControl
- Protección contra reentrancy
- Verificación en BaseScan para transparencia

## Estructura del Proyecto

```
.
├── contracts/                    # Contratos inteligentes
│   ├── interfaces/               # Interfaces y contratos abstractos
│   │   ├── IMusicCollection.sol  # Interface para colecciones musicales
│   │   ├── IMusicNFTFactory.sol  # Interface para el factory principal
│   │   └── IRevenueShare.sol     # Interface para distribución de ingresos
│   ├── MusicCollection.sol       # Implementación del NFT ERC1155
│   ├── MusicNFTFactory.sol       # Factory para crear colecciones
│   ├── RevenueShare.sol          # Sistema de distribución de ingresos
│   └── RevenueShareFactory.sol   # Factory para crear distribuidores
│
├── scripts/                      # Scripts de despliegue y utilidades
│   ├── utils/                    # Funciones auxiliares para scripts
│   │   └── deploy-helpers.js     # Utilidades de despliegue
│   ├── deploy.js                 # Script principal de despliegue
│   ├── deploy-revenue-share.js   # Despliegue del sistema de ingresos
│   ├── deploy-all.js             # Despliegue completo de toda la plataforma
│   └── create-collection.js      # Crear colección de ejemplo
│
├── test/                         # Tests automatizados
│   ├── utils/                    # Utilidades para testing
│   └── MusicNFTFactory.test.js   # Tests para el factory principal
│
├── .env                          # Variables de entorno (no incluir en git)
├── hardhat.config.js             # Configuración de hardhat
└── README.md                     # Documentación del proyecto
```

## Instalación

```bash
npm install
```

## Compilación

```bash
npm run compile
```

## Testing

```bash
npm run test
```

## Scripts Disponibles

### Desarrollo

- `npm run compile` - Compila los contratos
- `npm run test` - Ejecuta los tests
- `npm run coverage` - Genera reporte de cobertura
- `npm run clean` - Limpia archivos generados
- `npm run lint` - Formatea código Solidity

### Despliegue

- `npm run deploy` - Despliegue básico del factory
- `npm run deploy:sepolia` - Despliega en Base Sepolia
- `npm run deploy:revenue` - Despliega sistema de distribución de ingresos
- `npm run deploy:all` - Despliega toda la plataforma completa

### Utilidades

- `npm run create-collection` - Crea una colección de ejemplo
- `npm run node` - Inicia nodo local de hardhat

## Configuración de Red

El proyecto está configurado para desplegar en:

- **Base Sepolia** (testnet): Chain ID 84532
- **Hardhat Local Network**: Para desarrollo local

## Variables de Entorno

Crea un archivo `.env` con:

```bash
PRIVATE_KEY=tu_clave_privada_aquí
ETHERSCAN_API_KEY=tu_api_key_de_basescan
```

## Arquitectura de Contratos

### MusicNFTFactory

Factory principal que permite a los artistas crear sus propias colecciones ERC1155 con configuraciones personalizadas de pricing, fechas, y royalties.

### MusicCollection

Implementación ERC1155 con funcionalidades específicas para NFTs musicales, incluyendo:

- Mint pagado y gratuito
- Soporte para múltiples tokens de pago
- Royalties automáticos
- Control de fechas de mint

### RevenueShare

Sistema avanzado de distribución automática de ingresos que permite:

- Configuración de splits para mint y reventa
- Herencia de ingresos en remixes y playlists
- Distribución automática en ETH y ERC20
- Sistema de roles para gestión colaborativa

### RevenueShareFactory

Factory para crear contratos RevenueShare personalizados por artista, permitiendo múltiples configuraciones de distribución por artista.

## Ejemplos de Uso

### Crear una Colección NFT

```bash
npm run create-collection
```

### Configurar Distribución de Ingresos

Los artistas pueden crear múltiples contratos de distribución para diferentes proyectos usando el RevenueShareFactory.

## Seguridad

- Auditorías de OpenZeppelin para contratos base
- Protección contra reentrancy
- Validación exhaustiva de parámetros
- Sistema de roles con AccessControl
- Verificación en BaseScan para transparencia
