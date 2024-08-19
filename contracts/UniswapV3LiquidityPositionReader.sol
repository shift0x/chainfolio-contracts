// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

import './interfaces/uniswap/v3/INonfungiblePositionManager.sol';
import './interfaces/IERC721Enumerable.sol';

import './models/PoolState.sol';

import './lib/BytesUtil.sol';

import 'hardhat/console.sol';

struct NonFungiblePosition {
    uint96 nonce;
    address operator;
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint128 liquidity;
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    uint128 tokensOwed0;
    uint128 tokensOwed1;
}

contract UniswapV3LiquidityPositionReader {

    function getLiquidityPoolsWithPositions(address owner, 
        address[] memory pools, 
        INonfungiblePositionManager positionManager
    ) public view returns (LiquidityPool[] memory liquidityPools, LiquidityPosition[] memory liquidityPositions){
        liquidityPools = new LiquidityPool[](pools.length);

        for(uint256 i=0; i < pools.length; i++){
            IUniswapV3PoolImmutables pool = IUniswapV3PoolImmutables(pools[i]);
            
            liquidityPools[i] = LiquidityPool(
                address(pool),
                pool.token0(),
                pool.token1(),
                pool.fee()
            );
        }

        liquidityPositions = getLiquidityPositions(owner, positionManager);
    }

    function getLiquidityPositions(address owner,
        INonfungiblePositionManager positionManager
    ) public view returns (LiquidityPosition[] memory positions) {

        bytes memory positionIds;
        uint256 index = 0;

        while(true){
            bytes memory args = abi.encodeWithSelector(IERC721Enumerable.tokenOfOwnerByIndex.selector, owner, index);
            (bool success, bytes memory data) = address(positionManager).staticcall(args);

            if(!success) {break;}

            positionIds = abi.encodePacked(positionIds, data);

            index++;
        }

        positions = resolvePositions(positionIds, index, positionManager);
    }

    function resolvePositions(bytes memory ids, 
        uint256 count, 
        INonfungiblePositionManager positionManager
    ) private view returns (LiquidityPosition[] memory positions){
        positions = new LiquidityPosition[](count);
        
        uint256 positionId;

        for(uint256 i=0; i < positions.length; i++){
            positionId = BytesUtil.extractUint256(ids, i*32);
            positions[i] = getPosition(positionId, positionManager);
        }
    }

    function getPosition(uint256 id, 
        INonfungiblePositionManager positionManager
    ) private view returns (LiquidityPosition memory) {
        (,bytes memory result) = address(positionManager).staticcall(abi.encodeWithSelector(INonfungiblePositionManager.positions.selector, id));

        NonFungiblePosition memory nfp = abi.decode(result, (NonFungiblePosition));
        
        IUniswapV3Factory factory = IUniswapV3Factory(positionManager.factory());

        address pool = factory.getPool(nfp.token0, nfp.token1, nfp.fee);

        return LiquidityPosition({
            PositionId: id,
            LiquidityPool: pool,
            Token0: nfp.token0,
            Token1: nfp.token1,
            Active: nfp.liquidity > 0
        });
    }

    
}