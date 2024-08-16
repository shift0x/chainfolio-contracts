// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.12; 

struct Account {
    uint256 zrWalletIndex;
    bytes data;
    address eoa;
    bool active;
    bool created;
}