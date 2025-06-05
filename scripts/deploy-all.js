/**
 * Script para desplegar todos los factories
 */
const hre = require("hardhat");
const {
  deployAllFactories,
  //verifyContract,
} = require("./utils/deploy-helpers");

async function main() {
  console.log("🚀 Desplegando todos los factories...");

  // Desplegar todos los contracts
  const { musicFactory, revenueFactory } = await deployAllFactories();

  console.log("\n✅ Todos los contratos desplegados!");
  console.log("Para verificar los contratos:");
  console.log(
    `npx hardhat verify --network ${hre.network.name} ${musicFactory.factoryAddress}`
  );
  console.log(
    `npx hardhat verify --network ${hre.network.name} ${revenueFactory.factoryAddress}`
  );

  console.log("\n📝 Configuración para frontend:");
  console.log(`MUSIC_NFT_FACTORY_ADDRESS = "${musicFactory.factoryAddress}"`);
  console.log(
    `REVENUE_SHARE_FACTORY_ADDRESS = "${revenueFactory.factoryAddress}"`
  );

  // Verificar automáticamente
  //   if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
  //     console.log("\n🔍 Verificando contratos automáticamente...");
  //     await verifyContract(musicFactory.factoryAddress, []);
  //     await verifyContract(revenueFactory.factoryAddress, []);
  //   }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error en el despliegue:", error);
    process.exit(1);
  });
