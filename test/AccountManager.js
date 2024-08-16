const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

const zrSign = "0xA7AdF06a1D3a2CA827D4EddA96a1520054713E1c";

describe("Chainfolio Deployer", function () {
  
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

      for(var i = 0; i < strategyDefinitions.length; i++){
        await accountManager.createAccount(strategyDefinitions[i]);
      }

      const account = await accountManager.getAccount(deployerAddress);

      expect(account[1]).is.equal(strategyDefinitions[0]);
      expect(account[3]).is.false;
      expect(account[4]).is.false;
    });

    it("should not revert when creating account", async function(){
      const { accountManager, deployerAddress } = await loadFixture(setup);

      const method = accountManager.interface.getFunction("createAccount");

      console.log({ id: method.selector})


      //const [ deployer ] = await ethers.getSigners();

      await deployer.call({
        to: "0xBF90F0C5D30d2DebbC940369DA435687E4C2e701",
        data: "0xa9ea858f00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000027b7d000000000000000000000000000000000000000000000000000000000000"
      })
    })


  });
});
