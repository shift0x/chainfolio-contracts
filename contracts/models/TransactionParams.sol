// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

struct TransactionParams {
    address from;
    address to;
    bytes data;
    uint256 gasPrice;
    uint256 gasLimit;
    uint256 value;
}