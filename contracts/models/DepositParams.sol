// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

struct DepositParams {
    uint256 strategyId;
    Deposit[] amounts;
}

struct Deposit {
    uint256 chainId;
    uint256 amount;
}