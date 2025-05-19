/**
 * Helpers para despliegue de contratos
 */
const { ethers } = require("hardhat");

/**
 * Despliega el contrato Factory
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
  verifyContract,
};
