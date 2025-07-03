const { ethers, upgrades } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Desplegando TODOS los contratos upgradeables...\n");

  const deploymentInfo = {
    network: await ethers.provider.getNetwork(),
    timestamp: new Date().toISOString(),
    contracts: {},
  };

  // ============================================================================
  // 1. DESPLEGAR MUSIC COLLECTION + FACTORY
  // ============================================================================

  console.log("📦 1. Desplegando MusicCollectionUpgradeable implementation...");
  const MusicCollectionUpgradeable = await ethers.getContractFactory(
    "MusicCollectionUpgradeable"
  );
  const collectionImplementation = await MusicCollectionUpgradeable.deploy();
  await collectionImplementation.waitForDeployment();

  const collectionImplAddress = await collectionImplementation.getAddress();
  console.log(
    "✅ MusicCollectionUpgradeable implementation:",
    collectionImplAddress
  );

  console.log("\n📦 2. Desplegando MusicNFTFactoryUpgradeable...");
  const MusicNFTFactoryUpgradeable = await ethers.getContractFactory(
    "MusicNFTFactoryUpgradeable"
  );

  const musicFactory = await upgrades.deployProxy(
    MusicNFTFactoryUpgradeable,
    [collectionImplAddress],
    {
      kind: "uups",
      initializer: "initialize",
    }
  );

  await musicFactory.waitForDeployment();
  const musicFactoryAddress = await musicFactory.getAddress();
  const musicFactoryImplAddress =
    await upgrades.erc1967.getImplementationAddress(musicFactoryAddress);

  console.log("✅ MusicNFTFactoryUpgradeable proxy:", musicFactoryAddress);
  console.log(
    "📋 MusicNFTFactoryUpgradeable implementation:",
    musicFactoryImplAddress
  );

  // ============================================================================
  // 3. DESPLEGAR REVENUE SHARE + FACTORY
  // ============================================================================

  console.log("\n📦 3. Desplegando RevenueShareUpgradeable implementation...");
  const RevenueShareUpgradeable = await ethers.getContractFactory(
    "RevenueShareUpgradeable"
  );
  const revenueShareImplementation = await RevenueShareUpgradeable.deploy();
  await revenueShareImplementation.waitForDeployment();

  const revenueShareImplAddress = await revenueShareImplementation.getAddress();
  console.log(
    "✅ RevenueShareUpgradeable implementation:",
    revenueShareImplAddress
  );

  console.log("\n📦 4. Desplegando RevenueShareFactoryUpgradeable...");
  const RevenueShareFactoryUpgradeable = await ethers.getContractFactory(
    "RevenueShareFactoryUpgradeable"
  );

  const [deployer] = await ethers.getSigners();
  const revenueFactory = await upgrades.deployProxy(
    RevenueShareFactoryUpgradeable,
    [revenueShareImplAddress, deployer.address], // implementation + owner
    {
      kind: "uups",
      initializer: "initialize",
    }
  );

  await revenueFactory.waitForDeployment();
  const revenueFactoryAddress = await revenueFactory.getAddress();
  const revenueFactoryImplAddress =
    await upgrades.erc1967.getImplementationAddress(revenueFactoryAddress);

  console.log(
    "✅ RevenueShareFactoryUpgradeable proxy:",
    revenueFactoryAddress
  );
  console.log(
    "📋 RevenueShareFactoryUpgradeable implementation:",
    revenueFactoryImplAddress
  );

  // ============================================================================
  // 5. VERIFICAR DEPLOYMENTS
  // ============================================================================

  console.log("\n🔍 Verificando deployments...");

  const musicFactoryVersion = await musicFactory.version();
  const revenueFactoryVersion = await revenueFactory.version();
  const collectionImpl = await musicFactory.collectionImplementation();
  const revenueImpl = await revenueFactory.revenueShareImplementation();

  console.log("📌 MusicNFTFactory version:", musicFactoryVersion);
  console.log("📌 RevenueShareFactory version:", revenueFactoryVersion);
  console.log("📌 Collection impl configurada:", collectionImpl);
  console.log("📌 RevenueShare impl configurada:", revenueImpl);

  // ============================================================================
  // 6. GUARDAR INFORMACIÓN
  // ============================================================================

  deploymentInfo.contracts = {
    // Music NFT contracts
    musicFactoryProxy: musicFactoryAddress,
    musicFactoryImplementation: musicFactoryImplAddress,
    collectionImplementation: collectionImplAddress,

    // Revenue Share contracts
    revenueFactoryProxy: revenueFactoryAddress,
    revenueFactoryImplementation: revenueFactoryImplAddress,
    revenueShareImplementation: revenueShareImplAddress,
  };

  fs.writeFileSync(
    "./deployment-upgradeable-complete.json",
    JSON.stringify(deploymentInfo, null, 2)
  );

  // ============================================================================
  // 7. RESUMEN FINAL
  // ============================================================================

  console.log("\n📄 RESUMEN COMPLETO DEL DEPLOYMENT:");
  console.log("==========================================");
  console.log("🎵 MUSIC NFT CONTRACTS:");
  console.log("  🏭 Factory Proxy:", musicFactoryAddress);
  console.log("  🔧 Factory Implementation:", musicFactoryImplAddress);
  console.log("  📜 Collection Implementation:", collectionImplAddress);
  console.log("");
  console.log("💰 REVENUE SHARE CONTRACTS:");
  console.log("  🏭 Factory Proxy:", revenueFactoryAddress);
  console.log("  🔧 Factory Implementation:", revenueFactoryImplAddress);
  console.log("  📜 RevenueShare Implementation:", revenueShareImplAddress);
  console.log("==========================================\n");

  console.log("✨ Deployment completo exitoso!");
  console.log("📝 Info guardada en deployment-upgradeable-complete.json");

  console.log("\n💡 PRÓXIMOS PASOS:");
  console.log("1. Actualizar tu frontend con estas direcciones:");
  console.log(`   MUSIC_NFT_FACTORY = "${musicFactoryAddress}"`);
  console.log(`   REVENUE_SHARE_FACTORY = "${revenueFactoryAddress}"`);
  console.log("2. Para upgrades futuros usa: npm run upgrade");
  console.log("3. Verificar contratos en Etherscan (opcional)");

  // ============================================================================
  // 8. CREAR ARCHIVO DE CONFIGURACIÓN PARA FRONTEND
  // ============================================================================

  const frontendConfig = {
    MUSIC_NFT_FACTORY_ADDRESS: musicFactoryAddress,
    REVENUE_SHARE_FACTORY_ADDRESS: revenueFactoryAddress,
    NETWORK: deploymentInfo.network.name,
    DEPLOYED_AT: deploymentInfo.timestamp,
  };

  fs.writeFileSync(
    "./frontend-config.json",
    JSON.stringify(frontendConfig, null, 2)
  );

  console.log(
    "📱 Configuración para frontend guardada en frontend-config.json"
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error durante el deployment:", error);
    process.exit(1);
  });
