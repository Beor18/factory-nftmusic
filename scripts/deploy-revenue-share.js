/**
 * Script para desplegar solo el RevenueShareFactory
 */
const hre = require("hardhat");
const {
  deployRevenueShareFactory,
  //verifyContract,
} = require("./utils/deploy-helpers");

async function main() {
  console.log("🚀 Desplegando RevenueShareFactory...");

  // Desplegar RevenueShareFactory
  const { factoryAddress } = await deployRevenueShareFactory();

  // Registrar información para verificación
  console.log("\n✅ Despliegue completado!");
  console.log("Para verificar el contrato:");
  console.log(
    `npx hardhat verify --network ${hre.network.name} ${factoryAddress}`
  );

  // Guardar dirección en archivo de configuración (opcional)
  console.log("\n📝 Guarda esta dirección en tu frontend:");
  console.log(`REVENUE_SHARE_FACTORY_ADDRESS = "${factoryAddress}"`);

  // Verificar automáticamente en redes de testnet/mainnet
  //   if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
  //     console.log("\n🔍 Verificando contrato automáticamente...");
  //     await verifyContract(factoryAddress, []);
  //   }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error en el despliegue:", error);
    process.exit(1);
  });
