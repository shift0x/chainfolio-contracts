require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20"
      },
      {
        version: "0.7.6"
      },
    ]
  },
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
        url: "https://ethereum-sepolia-rpc.publicnode.com",
        //url: "https://sepolia-rollup.arbitrum.io/rpc",
        //blockNumber: 71904291
      },
    }
  }
};
