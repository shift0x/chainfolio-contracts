// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.12; 

struct TransactionParams {
    address to;
    bytes data;
    uint256 gasPrice;
    uint256 gasLimit;
    uint256 value;
    string chainId;

    uint256 zrWalletIndex;
    uint256 nonce;
    address eoa;
}