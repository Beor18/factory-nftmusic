/**
 * Script para crear una colección de ejemplo
 */
const hre = require("hardhat");

async function main() {
  // Obtener la dirección del contrato factory (reemplazar con la dirección real después del despliegue)
  const factoryAddress =
    process.env.FACTORY_ADDRESS || "0x1234567890123456789012345678901234567890";

  // Obtener la instancia del contrato
  const MusicNFTFactory = await hre.ethers.getContractFactory(
    "MusicNFTFactory"
  );
  const factory = MusicNFTFactory.attach(factoryAddress);

  console.log("Creando colección de ejemplo...");

  const currentTimestamp = Math.floor(Date.now() / 1000);
  const startDate = currentTimestamp; // Empieza ahora
  const endDate = currentTimestamp + 30 * 24 * 60 * 60; // Termina en 30 días

  // Crear colección
  const tx = await factory.createCollection(
    "Mi Colección Musical", // nombre
    "MUSIC", // símbolo
    "https://api.midominio.com/metadata/", // baseURI
    startDate,
    endDate,
    hre.ethers.parseEther("0.05"), // precio de mint: 0.05 ETH
    hre.ethers.ZeroAddress, // Sin token ERC20 por defecto
    process.env.ROYALTY_RECEIVER ||
      "0x1234567890123456789012345678901234567890", // Dirección que recibe royalties
    500 // 5% de royalties (500 de 10000)
  );

  const receipt = await tx.wait();

  // Buscar el evento CollectionCreated
  const events = receipt.logs.filter((log) => {
    try {
      const parsedLog = factory.interface.parseLog({
        topics: log.topics,
        data: log.data,
      });
      return parsedLog && parsedLog.name === "CollectionCreated";
    } catch (e) {
      return false;
    }
  });

  if (events.length > 0) {
    const event = factory.interface.parseLog({
      topics: events[0].topics,
      data: events[0].data,
    });
    console.log(
      `Colección creada con éxito en la dirección: ${event.args.collectionAddress}`
    );
    console.log(`Nombre: ${event.args.name}`);
    console.log(`Símbolo: ${event.args.symbol}`);
  } else {
    console.log(
      "Colección creada, pero no se pudo obtener la dirección del evento"
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
