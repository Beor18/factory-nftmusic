const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MusicNFTFactory", function () {
  let MusicNFTFactory;
  let factory;
  let owner;
  let artist;
  let user;

  beforeEach(async function () {
    [owner, artist, user] = await ethers.getSigners();

    // Crear contrato Factory
    MusicNFTFactory = await ethers.getContractFactory("MusicNFTFactory");
    factory = await MusicNFTFactory.deploy();
  });

  it("Debería desplegar la factory correctamente", async function () {
    expect(await factory.getAddress()).to.be.properAddress;
    expect(await factory.owner()).to.equal(owner.address);
  });

  it("Debería permitir crear una colección", async function () {
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const startDate = currentTimestamp;
    const endDate = currentTimestamp + 30 * 24 * 60 * 60;

    const tx = await factory
      .connect(artist)
      .createCollection(
        "Test Collection",
        "TEST",
        "https://test.com/",
        startDate,
        endDate,
        ethers.parseEther("0.05"),
        ethers.ZeroAddress,
        artist.address,
        500
      );

    const receipt = await tx.wait();

    // Verificar que se emitió el evento CollectionCreated
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

    expect(events.length).to.be.greaterThan(0);

    const event = factory.interface.parseLog({
      topics: events[0].topics,
      data: events[0].data,
    });

    expect(event.args.artist).to.equal(artist.address);
    expect(event.args.name).to.equal("Test Collection");
    expect(event.args.symbol).to.equal("TEST");

    // Verificar que la colección se agregó correctamente
    expect(await factory.getArtistCollectionsCount(artist.address)).to.equal(1);
    expect(await factory.getCollectionsCount()).to.equal(1);
  });
});
