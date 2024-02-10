const { expect } = require("chai");
const { ethers, web3, contract } = require("hardhat");

describe("PetRace", function () {
  it("Should deploy PetRace", async function () {
    const PetRace = await ethers.getContractFactory("PetRace");
    const petRace = await PetRace.deploy();
    await petRace.deployed();

    expect(petRace.address).to.not.equal(0);
  });
});
