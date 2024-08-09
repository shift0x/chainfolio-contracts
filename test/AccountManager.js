const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const executor = "0x4730505e6ccde0e6ac8b30b9d5a7875f9e191219";
const zrSign = "0xA7AdF06a1D3a2CA827D4EddA96a1520054713E1c";

describe("Chainfolio Deployer", function () {
  
  async function setup() {
    const [deployer] = await ethers.getSigners();

    const accountManagerContract = await ethers.getContractFactory("AccountManager");

    const accountManager = await accountManagerContract.deploy(executor, zrSign);

    await accountManager.waitForDeployment();

    const accountManagerAddress = await accountManager.getAddress();
    const deployerAddress = await deployer.getAddress();
    const amount = ethers.AbiCoder.defaultAbiCoder().encode(["uint256"], [ethers.parseEther("1")]) 

    // Set the balance of the signer account
    await ethers.provider.send("hardhat_setBalance", [accountManagerAddress, amount]);

    return { accountManager, accountManagerAddress, deployer, deployerAddress }
  }

  describe("Wallets", function () {

    it("should create new strategy", async function(){
      const { accountManager, deployerAddress } = await loadFixture(setup);
      const strategyDefinitions = [
        "0x01",
        "0x02",
        "0x03"
      ]

      for(var i = 0; i < strategyDefinitions.length; i++){
        await accountManager.createStrategy(strategyDefinitions[i]);
      }

      const strategies = await accountManager.getAccountStrategies(deployerAddress);

      expect(strategies.length).is.equal(strategyDefinitions.length);

      for(var i = 0; i < strategyDefinitions.length; i++){
        const actual = strategies[i];

        expect(actual[0]).is.equal(i);
        expect(actual[2]).is.equal(strategyDefinitions[i]);
        expect(actual[3]).is.true;
      }
    });


  });
});
