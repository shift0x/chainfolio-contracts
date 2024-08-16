// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.12;

import './interfaces/IERC20.sol';

struct TokenBalance {
    address addr;
    uint256 balance;
    uint256 decimals;
}

struct AccountBalances {
    uint256 chainId;
    uint256 nativeBalance;
    TokenBalance[] tokens;
}

contract AccountBalancesLookup {

    function getAccountBalances(uint256 chainId, address owner, address[] memory tokens) public view returns (AccountBalances memory balances) {
        balances.chainId = chainId;
        balances.nativeBalance = owner.balance;
        balances.tokens = new TokenBalance[](tokens.length);

        for(uint8 i =0; i < tokens.length; i++){
            balances.tokens[i] = TokenBalance(tokens[i], 
                IERC20(tokens[i]).balanceOf(owner),
                IERC20(tokens[i]).decimals());
        }

        return balances;
    }
}