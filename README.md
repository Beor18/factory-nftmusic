# Factory de NFTs ERC1155 para Artistas Musicales

Este proyecto implementa una plataforma de NFTs para artistas musicales utilizando el estándar ERC1155. Permite a los artistas crear colecciones de NFTs con soporte para royalties, múltiples opciones de pago, y gestión de fechas de mint.

## Características

- Factory de ERC1155 para artistas musicales
- Soporte completo para royalties (ERC2981)
- Mint con ETH nativo o tokens ERC20
- Opción de free mint para propietarios
- Fechas configurables de inicio y fin de mint
- Despliegue en Base Sepolia

## Estructura del Proyecto

```
.
├── contracts/               # Contratos inteligentes
│   ├── interfaces/          # Interfaces y contratos abstractos
│   ├── libraries/           # Bibliotecas compartidas
│   ├── MusicCollection.sol  # Implementación del NFT ERC1155
│   └── MusicNFTFactory.sol  # Factory para crear colecciones
│
├── scripts/                 # Scripts de despliegue y utilidades
│   ├── utils/               # Funciones auxiliares para scripts
│   ├── tests/               # Scripts para pruebas en redes
│   ├── deploy.js            # Script principal de despliegue
│   └── create-collection.js # Crear colección de ejemplo
│
├── test/                    # Tests automatizados
│   ├── utils/               # Utilidades para testing
│   └── MusicNFTFactory.test.js # Tests para el factory
│
├── .env                     # Variables de entorno (no incluir en git)
├── hardhat.config.js        # Configuración de hardhat
└── README.md                # Documentación del proyecto
```

## Instalación

```bash
npm install
```

## Compilación

```bash
npx hardhat compile
```

## Testing

```bash
npx hardhat test
```

## Despliegue

```bash
npx hardhat run scripts/deploy.js --network baseSepolia
```

## Licencia

MIT
