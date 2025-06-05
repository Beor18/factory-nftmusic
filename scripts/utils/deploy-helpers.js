/**
 * Helpers para despliegue de contratos
 */
const { ethers } = require("hardhat");

/**
 * Despliega el contrato MusicNFTFactory
 * @returns {Promise<Object>} - Contrato factory desplegado
 */
async function deployFactory() {
  console.log("Desplegando MusicNFTFactory...");

  const MusicNFTFactory = await ethers.getContractFactory("MusicNFTFactory");
  const factory = await MusicNFTFactory.deploy();

  await factory.waitForDeployment();

  const factoryAddress = await factory.getAddress();
  console.log(`MusicNFTFactory desplegado en: ${factoryAddress}`);

  return { factory, factoryAddress };
}

/**
 * Despliega el contrato RevenueShareFactory
 * @returns {Promise<Object>} - Contrato RevenueShareFactory desplegado
 */
async function deployRevenueShareFactory() {
  console.log("Desplegando RevenueShareFactory...");

  const RevenueShareFactory = await ethers.getContractFactory(
    "RevenueShareFactory"
  );
  const factory = await RevenueShareFactory.deploy();

  await factory.waitForDeployment();

  const factoryAddress = await factory.getAddress();
  console.log(`RevenueShareFactory desplegado en: ${factoryAddress}`);

  return { factory, factoryAddress };
}

/**
 * Despliega ambos factories
 * @returns {Promise<Object>} - Ambos contratos desplegados
 */
async function deployAllFactories() {
  console.log("Desplegando todos los factories...");

  const musicFactory = await deployFactory();
  const revenueFactory = await deployRevenueShareFactory();

  console.log("\n=== RESUMEN DE DESPLIEGUE ===");
  console.log(`MusicNFTFactory: ${musicFactory.factoryAddress}`);
  console.log(`RevenueShareFactory: ${revenueFactory.factoryAddress}`);

  return {
    musicFactory,
    revenueFactory,
  };
}

/**
 * Verifica un contrato en Etherscan/Basescan
 * @param {string} address - Dirección del contrato a verificar
 * @param {Array} constructorArgs - Argumentos del constructor
 */
async function verifyContract(address, constructorArgs) {
  console.log(`Verificando contrato en ${address}...`);
  try {
    await hre.run("verify:verify", {
      address: address,
      constructorArguments: constructorArgs,
    });
    console.log("Contrato verificado con éxito");
  } catch (error) {
    console.log(`Error al verificar: ${error.message}`);
  }
}

module.exports = {
  deployFactory,
  deployRevenueShareFactory,
  deployAllFactories,
  verifyContract,
};
