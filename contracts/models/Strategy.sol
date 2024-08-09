// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

struct Strategy {
    uint256 id;
    uint256 zrWalletIndex;
    bytes instructions;
    bool active;
}