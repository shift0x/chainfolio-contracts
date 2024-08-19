const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

// ETH Sepolia
const UniswapV3LiquidityPositionManager = "0x1238536071E1c677A632429e3655c799b22cDA52";
const ContractAddress = "0x103390067E59956Cb3feF17f18fe421eD265e5f4"
const rpc = "https://ethereum-sepolia-rpc.publicnode.com";

// testnet rpcs are too unstable to support deploying contract so we need to use the local
// network, then use a state override call to read data from the testnet
async function callPositionManager(reader, method, ...args){
    const calldata = reader.interface.encodeFunctionData(method, args);
    const readerAddress = await reader.getAddress();
    const byteCode = await ethers.provider.getCode(readerAddress);
    const stateOverride = {}

    stateOverride[ContractAddress] = {
        code: byteCode
    }

    const networkProvider = new ethers.JsonRpcProvider(rpc);

    const rawResult = await networkProvider.send('eth_call', [
        {
            to: ContractAddress,
            data: calldata,
        },
        'latest',
        stateOverride,
    ]);

    return reader.interface.decodeFunctionResult(method, rawResult);
}

describe("Position Reader", function () {

    async function setup() {
        const uniswapV3LiquidityPositionReaderContract = await ethers.getContractFactory("UniswapV3LiquidityPositionReader");
        const liquidityPositionReader = await uniswapV3LiquidityPositionReaderContract.deploy();
    
        await liquidityPositionReader.waitForDeployment();
    
        return { liquidityPositionReader}
      }

    
    it("should read positions", async function(){
        const { liquidityPositionReader } = await loadFixture(setup);

        const owner = "0xb231356EC0f754675A0DFEFc25132CEd4df38E76";
        const positions = (await callPositionManager(liquidityPositionReader, "getLiquidityPositions", owner, UniswapV3LiquidityPositionManager))[0];

        expect(positions.length).is.greaterThan(0);
    });

    it("should read pools with positions", async function(){
        const { liquidityPositionReader } = await loadFixture(setup);

        const owner = "0xb231356EC0f754675A0DFEFc25132CEd4df38E76";
        const addresses = [
            "0xdd7cc9a0da070fb8b60dc6680b596133fb4a7100",
            "0x1c9d93e574be622821398e3fe677e3a279f256f7",
            "0x3289680dd4d6c10bb19b899729cda5eef58aeff1",
            "0x1f358bd2b4EA422F7a75b9E20DEb32f4723E8aAB"
        ]

        const [pools, positions] = await callPositionManager(liquidityPositionReader, "getLiquidityPoolsWithPositions", owner, addresses, UniswapV3LiquidityPositionManager);

        expect(pools.length).is.equal(addresses.length);
        expect(positions.length).is.greaterThan(0);
    });

});
