// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import '../models/Strategy.sol';

interface IAccountManager {
    function createStrategy(bytes calldata instructions) external;

    function getStrategyAddress(uint256 zrWalletIndex) external view returns (string memory);

    function setStrategy(uint256 id, bytes calldata instructions) external;

    function _accountStrategies(address owner) external view returns (Strategy[] memory);
}