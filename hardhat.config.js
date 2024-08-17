require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    eth_sepolia: {
      url: "https://ethereum-sepolia-rpc.publicnode.com",
      accounts: [ vars.get("SMART_CONTRACT_DEPLOYER") ],
    },
    arb_sepolia: {
      url: "https://sepolia-rollup.arbitrum.io/rpc",
      accounts: [ vars.get("SMART_CONTRACT_DEPLOYER") ],
    },
    hardhat: {
      forking: {
        url: "https://sepolia-rollup.arbitrum.io/rpc",
      },
    }
  }
};
