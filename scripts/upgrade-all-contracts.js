const { ethers, upgrades } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🔄 Iniciando proceso de upgrade completo...\n");

  // Leer información del deployment anterior
  let deploymentInfo;
  try {
    const data = fs.readFileSync(
      "./deployment-upgradeable-complete.json",
      "utf8"
    );
    deploymentInfo = JSON.parse(data);
    console.log("📖 Información de deployment anterior cargada");
  } catch (error) {
    console.error("❌ No se pudo leer deployment-upgradeable-complete.json");
    console.log(
      "💡 Asegúrate de haber desplegado los contratos primero con deploy-all-upgradeable.js"
    );
    process.exit(1);
  }

  const musicFactoryProxy = deploymentInfo.contracts.musicFactoryProxy;
  const revenueFactoryProxy = deploymentInfo.contracts.revenueFactoryProxy;

  console.log("🎯 Contratos a actualizar:");
  console.log("  🎵 MusicNFTFactory Proxy:", musicFactoryProxy);
  console.log("  💰 RevenueShareFactory Proxy:", revenueFactoryProxy);

  const upgradedContracts = {};

  // ============================================================================
  // 1. UPGRADE MUSIC NFT FACTORY
  // ============================================================================

  console.log("\n📦 1. Preparando upgrade de MusicNFTFactoryUpgradeable...");
  const MusicNFTFactoryUpgradeableV2 = await ethers.getContractFactory(
    "MusicNFTFactoryUpgradeable"
  );

  console.log("🔄 Ejecutando upgrade del MusicNFTFactory...");
  const upgradedMusicFactory = await upgrades.upgradeProxy(
    musicFactoryProxy,
    MusicNFTFactoryUpgradeableV2,
    { kind: "uups" }
  );

  const newMusicFactoryImplAddress =
    await upgrades.erc1967.getImplementationAddress(musicFactoryProxy);
  const musicFactoryVersion = await upgradedMusicFactory.version();

  console.log("✅ MusicNFTFactory actualizado exitosamente!");
  console.log("📌 Nueva implementación:", newMusicFactoryImplAddress);
  console.log("📌 Nueva versión:", musicFactoryVersion);

  upgradedContracts.musicFactory = {
    proxy: musicFactoryProxy,
    implementation: newMusicFactoryImplAddress,
    version: musicFactoryVersion,
  };

  // ============================================================================
  // 2. UPGRADE REVENUE SHARE FACTORY
  // ============================================================================

  console.log(
    "\n📦 2. Preparando upgrade de RevenueShareFactoryUpgradeable..."
  );
  const RevenueShareFactoryUpgradeableV2 = await ethers.getContractFactory(
    "RevenueShareFactoryUpgradeable"
  );

  console.log("🔄 Ejecutando upgrade del RevenueShareFactory...");
  const upgradedRevenueFactory = await upgrades.upgradeProxy(
    revenueFactoryProxy,
    RevenueShareFactoryUpgradeableV2,
    { kind: "uups" }
  );

  const newRevenueFactoryImplAddress =
    await upgrades.erc1967.getImplementationAddress(revenueFactoryProxy);
  const revenueFactoryVersion = await upgradedRevenueFactory.version();

  console.log("✅ RevenueShareFactory actualizado exitosamente!");
  console.log("📌 Nueva implementación:", newRevenueFactoryImplAddress);
  console.log("📌 Nueva versión:", revenueFactoryVersion);

  upgradedContracts.revenueFactory = {
    proxy: revenueFactoryProxy,
    implementation: newRevenueFactoryImplAddress,
    version: revenueFactoryVersion,
  };

  // ============================================================================
  // 3. UPGRADE IMPLEMENTATIONS (OPCIONAL)
  // ============================================================================

  const updateCollectionImpl = process.argv.includes("--update-collection");
  const updateRevenueShareImpl = process.argv.includes(
    "--update-revenue-share"
  );

  // 3a. Actualizar Collection Implementation
  if (updateCollectionImpl) {
    console.log(
      "\n📦 3a. Desplegando nueva implementación de MusicCollectionUpgradeable..."
    );
    const MusicCollectionUpgradeableV2 = await ethers.getContractFactory(
      "MusicCollectionUpgradeable"
    );
    const newCollectionImpl = await MusicCollectionUpgradeableV2.deploy();
    await newCollectionImpl.waitForDeployment();

    const newCollectionImplAddress = await newCollectionImpl.getAddress();
    console.log(
      "✅ Nueva Collection Implementation:",
      newCollectionImplAddress
    );

    console.log("🔄 Actualizando referencia en MusicNFTFactory...");
    await upgradedMusicFactory.updateCollectionImplementation(
      newCollectionImplAddress
    );
    console.log("✅ Referencia actualizada en el Factory");

    deploymentInfo.contracts.collectionImplementation =
      newCollectionImplAddress;
    upgradedContracts.collectionImplementation = newCollectionImplAddress;
  }

  // 3b. Actualizar RevenueShare Implementation
  if (updateRevenueShareImpl) {
    console.log(
      "\n📦 3b. Desplegando nueva implementación de RevenueShareUpgradeable..."
    );
    const RevenueShareUpgradeableV2 = await ethers.getContractFactory(
      "RevenueShareUpgradeable"
    );
    const newRevenueShareImpl = await RevenueShareUpgradeableV2.deploy();
    await newRevenueShareImpl.waitForDeployment();

    const newRevenueShareImplAddress = await newRevenueShareImpl.getAddress();
    console.log(
      "✅ Nueva RevenueShare Implementation:",
      newRevenueShareImplAddress
    );

    console.log("🔄 Actualizando referencia en RevenueShareFactory...");
    await upgradedRevenueFactory.updateRevenueShareImplementation(
      newRevenueShareImplAddress
    );
    console.log("✅ Referencia actualizada en el Factory");

    deploymentInfo.contracts.revenueShareImplementation =
      newRevenueShareImplAddress;
    upgradedContracts.revenueShareImplementation = newRevenueShareImplAddress;
  }

  // ============================================================================
  // 4. ACTUALIZAR ARCHIVO DE DEPLOYMENT
  // ============================================================================

  deploymentInfo.contracts.musicFactoryImplementation =
    newMusicFactoryImplAddress;
  deploymentInfo.contracts.revenueFactoryImplementation =
    newRevenueFactoryImplAddress;

  deploymentInfo.lastUpgrade = {
    timestamp: new Date().toISOString(),
    upgradedContracts,
  };

  fs.writeFileSync(
    "./deployment-upgradeable-complete.json",
    JSON.stringify(deploymentInfo, null, 2)
  );

  // ============================================================================
  // 5. VERIFICAR UPGRADES
  // ============================================================================

  console.log("\n🔍 Verificando upgrades...");

  const collectionImpl = await upgradedMusicFactory.collectionImplementation();
  const revenueImpl = await upgradedRevenueFactory.revenueShareImplementation();

  console.log("📌 Collection impl actual:", collectionImpl);
  console.log("📌 RevenueShare impl actual:", revenueImpl);

  // ============================================================================
  // 6. RESUMEN FINAL
  // ============================================================================

  console.log("\n📄 RESUMEN DEL UPGRADE:");
  console.log("==========================================");
  console.log("🎵 MUSIC NFT FACTORY:");
  console.log("  🏭 Proxy (sin cambios):", musicFactoryProxy);
  console.log("  🔧 Nueva Implementation:", newMusicFactoryImplAddress);
  console.log("  📌 Versión:", musicFactoryVersion);
  if (updateCollectionImpl) {
    console.log(
      "  📜 Nueva Collection Implementation:",
      upgradedContracts.collectionImplementation
    );
  }
  console.log("");
  console.log("💰 REVENUE SHARE FACTORY:");
  console.log("  🏭 Proxy (sin cambios):", revenueFactoryProxy);
  console.log("  🔧 Nueva Implementation:", newRevenueFactoryImplAddress);
  console.log("  📌 Versión:", revenueFactoryVersion);
  if (updateRevenueShareImpl) {
    console.log(
      "  📜 Nueva RevenueShare Implementation:",
      upgradedContracts.revenueShareImplementation
    );
  }
  console.log("==========================================\n");

  console.log("✨ Upgrade completo exitoso!");
  console.log(
    "📝 Información actualizada en deployment-upgradeable-complete.json"
  );

  // Mostrar opciones adicionales si no se usaron
  if (!updateCollectionImpl && !updateRevenueShareImpl) {
    console.log("\n💡 OPCIONES ADICIONALES para el próximo upgrade:");
    console.log(
      "  --update-collection      Actualizar Collection Implementation"
    );
    console.log(
      "  --update-revenue-share   Actualizar RevenueShare Implementation"
    );
    console.log(
      "  --update-collection --update-revenue-share   Actualizar ambos"
    );
    console.log("\nEjemplo:");
    console.log(
      "  npx hardhat run scripts/upgrade-all-contracts.js --update-collection"
    );
  }

  // ============================================================================
  // 7. ACTUALIZAR CONFIGURACIÓN FRONTEND
  // ============================================================================

  const frontendConfig = {
    MUSIC_NFT_FACTORY_ADDRESS: musicFactoryProxy,
    REVENUE_SHARE_FACTORY_ADDRESS: revenueFactoryProxy,
    NETWORK: deploymentInfo.network.name,
    LAST_UPDATED: new Date().toISOString(),
  };

  fs.writeFileSync(
    "./frontend-config.json",
    JSON.stringify(frontendConfig, null, 2)
  );

  console.log("📱 Configuración frontend actualizada en frontend-config.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error durante el upgrade:", error);
    process.exit(1);
  });
