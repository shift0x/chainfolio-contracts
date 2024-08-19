const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const zrSign = "0xa7adf06a1d3a2ca827d4edda96a1520054713e1c";

describe("Account Manager", function () {
  
  async function setup() {
    const [deployer] = await ethers.getSigners();

    const accountManagerContract = await ethers.getContractFactory("AccountManager");

    const accountManager = await accountManagerContract.deploy(zrSign);

    await accountManager.waitForDeployment();

    const accountManagerAddress = await accountManager.getAddress();
    const deployerAddress = await deployer.getAddress();
    const amount = ethers.AbiCoder.defaultAbiCoder().encode(["uint256"], [ethers.parseEther("1")]) 

    // Set the balance of the signer account
    await ethers.provider.send("hardhat_setBalance", [accountManagerAddress, amount]);

    return { accountManager, accountManagerAddress, deployer, deployerAddress }
  }

  describe("Wallets", function () {

    it.skip("should create new account", async function(){
      const { accountManager, deployerAddress } = await loadFixture(setup);
      const strategyDefinitions = ["0x01"]

      await accountManager.createAccount(deployerAddress, strategyDefinitions[i]);

      const account = await accountManager.getAccount(deployerAddress);

      expect(account[1]).is.equal(strategyDefinitions[0]);
      expect(account[3]).is.false;
      expect(account[4]).is.true;
    });

  });
});
