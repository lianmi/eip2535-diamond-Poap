import { expect } from "chai"
import { ethers } from "hardhat"

import { deployDiamond, upgradeDiamond } from '../scripts/deploy'

describe("EIP2535 Diamond Poap Main Test", () => {
  let diamondAddress:any;
  let diamondCutFacet:any;
  let diamondLoupeFacet:any;
  let ownershipFacet;
  let poapFacet:any;
  let tx;
  let receipt;
  let result;
  const addresses = [];
  
  before(async function () {
    diamondAddress = await deployDiamond(['PoapFacet'], 'init')
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    poapFacet = await ethers.getContractAt('PoapFacet', diamondAddress)
  });

  
  it("Should deploy", async () => {
    const x = await poapFacet.getX()
    console.log("x=", x.toNumber())
    expect(await poapFacet.getX()).to.equal(100)
    // x: 100 => 101
    await poapFacet.changeX()
    expect(await poapFacet.getX()).to.equal(101)
  });

  
  it('should have 4 facets -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address);
    }

    expect(addresses.length).to.equal(4);
  });


  it("should return correct name", async function() {
    const [owner, addr1, addr2] = await ethers.getSigners();
    expect(await poapFacet.name()).to.equal("PoapSBTs");
    expect(await poapFacet.symbol()).to.equal("PoapSBTs");
  });


  

  it("Should check POAPs' vars", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    // -------------------
    // Status checking
    expect(await poapFacet.paused()).to.equal(false);
    expect(await poapFacet.isAdmin(owner.address)).to.equal(true);
    expect(await poapFacet.isAdmin(addr1.address)).to.equal(true);
    expect(await poapFacet.isAdmin(addr2.address)).to.equal(false);
    await poapFacet.createEvent(1, "show#1");
    expect(await poapFacet.isEventMinter(1, owner.address)).to.equal(true);
    expect(await poapFacet.isEventMinter(1, addr1.address)).to.equal(true);
    expect(await poapFacet.isEventMinter(1, addr2.address)).to.equal(false);
  });

  it("Should check POAPEvent", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const EVENT = 128
    // -------------------
    // Poap event checking
    await expect(poapFacet.mintToken(EVENT, "poap-event-test", owner.address)).to.be.revertedWith("Poap: event not exists");
    await poapFacet.createEvent(EVENT, "event test");
    expect(await poapFacet.eventMetaName(EVENT)).to.equal("event test");
    await poapFacet.mintToken(EVENT, "poap-event-test", owner.address)
    expect(await poapFacet.eventHasUser(EVENT, owner.address)).to.equal(true);
    expect(await poapFacet.tokenEvent(await poapFacet.tokenOfOwnerByIndex(owner.address, 0))).to.equal(EVENT);
  });


  it("Should check POAPRole", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const EVENT = 256;

    await poapFacet.createEvent(EVENT, "show#2");
    // -------------------
    // PoapRole admin
    await poapFacet.connect(addr1).renounceAdmin(); // msg.send = addr1
    expect(await poapFacet.isAdmin(addr1.address)).to.equal(false);
    await poapFacet.addAdmin(addr1.address);
    expect(await poapFacet.isAdmin(addr1.address)).to.equal(true);

    await poapFacet.connect(owner).removeAdmin(addr1.address);

    expect(await poapFacet.isAdmin(addr1.address)).to.equal(false);
    await poapFacet.addAdmin(addr1.address);
    expect(await poapFacet.isAdmin(addr1.address)).to.equal(true);
    // -------------------
    // PoapRole event minter
    expect(await poapFacet.isEventMinter(EVENT, addr2.address)).to.equal(false);
    await poapFacet.addEventMinter(EVENT, addr2.address);
    expect(await poapFacet.isEventMinter(EVENT, addr2.address)).to.equal(true);
    await poapFacet.removeEventMinter(EVENT, addr2.address);
    expect(await poapFacet.isEventMinter(EVENT, addr2.address)).to.equal(false);
    await poapFacet.addEventMinter(EVENT, addr2.address);
    expect(await poapFacet.isEventMinter(EVENT, addr2.address)).to.equal(true);
    await poapFacet.connect(addr2).renounceEventMinter(EVENT);
    expect(await poapFacet.isEventMinter(EVENT, addr2.address)).to.equal(false);
  });


  it("Should check POAPPausable", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    // -------------------
    // Poap pause checking
    expect(await poapFacet.paused()).to.equal(false);
    await poapFacet.pause();
    expect(await poapFacet.paused()).to.equal(true);
    await poapFacet.unpause();
    expect(await poapFacet.paused()).to.equal(false);

  });
  it("Should check POAP mint", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    const baseURI = "https://sbts_poap.xyz/token/";
    const EVENT = 512;
    const EVENT2 = 1024;
    const afterBaseURI = baseURI + "sbt-poap-token/";

    await poapFacet.createEvent(EVENT, "show#3");
    await poapFacet.createEvent(EVENT2, "show#4");
    async function checkPoap(address:any, baseURI:any, index:any, poapFacet:any, shouldBalance:any, shouldId:any, shouldEvent:any) {
      expect(await poapFacet.balanceOf(address)).to.equal(shouldBalance);
      const [tokenId, eventId] = await poapFacet.tokenDetailsOfOwnerByIndex(address, index);
      expect(tokenId).to.equal(shouldId);
      expect(await poapFacet.tokenURI(tokenId)).to.equal(baseURI + `${shouldId}`);
      expect(eventId).to.equal(shouldEvent);
    }

    // -------------------
    // Poap mint checking
    await poapFacet.mintToken(EVENT, "poap-1", owner.address);
    await checkPoap(owner.address, baseURI, 0, poapFacet, 2, 1, 128)
    // each event can only assign once to one user
    await expect(poapFacet.mintToken(EVENT, "poap-2", owner.address)).to.be.revertedWith("Poap: already assigned the event");

    await poapFacet.mintEventToManyUsers(EVENT2, ["poap-2", "poap-3"], [owner.address, addr1.address]);
    await checkPoap(owner.address, baseURI, 1, poapFacet, 3, 2, EVENT)
    await checkPoap(addr1.address, baseURI, 0, poapFacet, 1, 4, EVENT2)

    await poapFacet.mintUserToManyEvents([EVENT, EVENT2], ["poap-4", "poap-5"], addr2.address);
    await checkPoap(addr2.address, baseURI, 0, poapFacet, 2, 5, EVENT)
    await checkPoap(addr2.address, baseURI, 1, poapFacet, 2, 6, EVENT2)

    await poapFacet.burn(4); // burn (EVENT, addr2)
    await checkPoap(addr2.address, baseURI, 0, poapFacet, 2, 5, EVENT)

    await poapFacet.setBaseURI(afterBaseURI);
    await checkPoap(addr2.address, afterBaseURI, 0, poapFacet, 2, 5, EVENT)
  });

  // -------------------
  // Poap basically is a ERC721 Token

  it("Should check POAP transforms", async function() {
    const EVENT =  2048;
    const [owner, addr1, addr2] = await ethers.getSigners();
    await poapFacet.createEvent(EVENT, "event for transforms");
    expect(await poapFacet.eventMetaName(EVENT)).to.equal("event for transforms");
    await poapFacet.mintToken(EVENT, "poap-event-transforms", owner.address)
    const [tokenId, eventId] = await poapFacet.tokenDetailsOfOwnerByIndex(owner.address, 0);

    const transferTx = await poapFacet.transferFrom(owner.address, addr1.address, tokenId);
    await transferTx.wait();
    expect(await poapFacet.ownerOf(tokenId)).to.equal(addr1.address);
  });

  it("Should upgrade ", async () => {
    
    // upgrade, s.y = 200
    await upgradeDiamond(diamondAddress, ['PoapFacetV2'], 'init2')
    const poapV2Facet = await ethers.getContractAt('PoapFacetV2', diamondAddress)
    const y = await poapV2Facet.getY()
    console.log("y=", y.toNumber())
    expect(await poapV2Facet.getY()).to.equal(200)

    // x: 101 => 111
    //v1里, 此方法是递增1, v2是递增10
    //为何不直接调用 test1V2Facet.changeX(), 答案是都一样，只不过之前已经写好了dapp的代码，所以可以不用改
    await poapV2Facet.changeX()
    // await test1V2Facet.changeX()

    
    const x2 = await poapV2Facet.getX()
    console.log("x2=", x2.toNumber())


    expect(await poapV2Facet.getX()).to.equal(111)
  });

})
