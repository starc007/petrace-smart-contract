// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

const platformFeeAddress = "0xD740387440012782E6D760b86B21b17b8d1166B5";

async function main() {
  const petRace = await hre.ethers.deployContract(
    "contracts/PetRace.sol:PetRace",
    [platformFeeAddress]
  );
  await petRace.waitForDeployment();

  console.log("<<<<<<PetRace deployed to:", petRace.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
