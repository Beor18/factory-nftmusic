/**
 * Script principal de despliegue
 */
const hre = require("hardhat");
const { deployFactory } = require("./utils/deploy-helpers");

async function main() {
  // Desplegar factory
  const { factoryAddress } = await deployFactory();

  // Registrar información para verificación
  console.log("Para verificar el contrato:");
  console.log(`npx hardhat verify --network baseSepolia ${factoryAddress}`);

  // Verificar automáticamente en redes compatibles
  // if (network.name !== "hardhat" && network.name !== "localhost") {
  //   await verifyContract(factoryAddress, []);
  // }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
