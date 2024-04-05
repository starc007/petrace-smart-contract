require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */

// const privateKey = "YOUR_PRIVATE_KEY";
const privateKey = "";

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },

  networks: {
    hardhat: {},
    blast_sepolia: {
      url: "https://sepolia.blast.io",
      accounts: [privateKey],
      gasPrice: 1000000000,
      saveDeployments: true,
    },
    zkSync: {
      url: "https://mainnet.era.zksync.io",
      accounts: [privateKey],
    },
  },
};
