/**
 * Script principal de despliegue
 */
const hre = require("hardhat");
const { deployFactory, verifyContract } = require("./utils/deploy-helpers");

async function main() {
  // Tarifa de creación: 0.01 ETH
  const creationFee = "0.01";

  // Desplegar factory
  const { factory, factoryAddress } = await deployFactory(creationFee);

  // Registrar información para verificación
  console.log("Para verificar el contrato:");
  console.log(
    `npx hardhat verify --network baseSepolia ${factoryAddress} ${hre.ethers.parseEther(
      creationFee
    )}`
  );

  // Verificar automáticamente en redes compatibles
  if (network.name !== "hardhat" && network.name !== "localhost") {
    await verifyContract(factoryAddress, [hre.ethers.parseEther(creationFee)]);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
