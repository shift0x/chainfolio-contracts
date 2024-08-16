// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.12;

import '../models/Account.sol';

interface IAccountManager {
    function createAccount(bytes calldata instructions) external;
}