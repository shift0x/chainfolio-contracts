// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;

struct LiquidityPosition {
    uint256 PositionId;
    address LiquidityPool;
    address Token0;
    address Token1;
    bool Active;
}

struct LiquidityPool {
    address Address;
    address Token0;
    address Token1;
    uint256 Fee;
}