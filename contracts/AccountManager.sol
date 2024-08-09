// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import './models/Strategy.sol';
import './models/DepositParams.sol';
import './models/TransactionParams.sol';

import './lib/zr/SignTypes.sol';

import './interfaces/zr/IZrSign.sol';
import './interfaces/IERC20.sol';

import './ZrSignConnect.sol';

contract AccountManager is ZrSignConnect {

    // Account transaction executor address
    address public immutable _executor;

    // mapping of users to managed wallet strategies
    mapping(address => Strategy[]) private _accountStrategies;

    // mapping of managed accounts to nonces on various chains
    // zrWalletIndex => (chainId => nonce)
    mapping(uint256 => mapping(bytes32 => uint256)) private _nonce;

    constructor(address executor, address zrSign) 
        ZrSignConnect(zrSign)
    {
        _executor = executor;
    }

    // Modifier to ensure the execution is only from the executor account
    modifier onlyExecutor(){
        require(msg.sender == _executor, "unauthorized");
        _;
    }

    /**
     * @dev Create a new managed strategy
     * 
     * @param instructions bytes representing the configuration of the strategy
     */
    function createStrategy(bytes calldata instructions) public {
        // create a new wallet with zrSign and store the walletId
        uint256 walletIndex = requestNewEVMWallet();

        // create a new strategy for the newly created wallet
        uint256 id = _accountStrategies[msg.sender].length;

        Strategy memory newStrategy = Strategy(id, walletIndex, instructions, true);

        _accountStrategies[msg.sender].push(newStrategy);
    }

    /**
     * @dev Updates a strategy for the given account id
     * 
     * @param id The id of the account to modify
     * @param instructions bytes representing the configuration of the strategy
     */
    function setStrategy(uint256 id, bytes calldata instructions) public {
        _accountStrategies[msg.sender][id].instructions = instructions;
    }

    /**
     * @dev Get the address for the EOA running the given strategy
     */
    function getStrategyAddress(uint256 zrWalletIndex) public view returns (string memory){
        return getEVMWallet(zrWalletIndex);
    }

    function getAccountStrategies(address account) public view returns (Strategy[] memory){
        return _accountStrategies[account];
    }

    /**
     * @dev Execute transactions on behalf of a given account
     *
     * @param payloads Transactions to execute
     */
    function execute(TransactionParams[] memory payloads, 
        uint256 zrWalletIndex, 
        bytes32 chainId
    ) public onlyExecutor {
        for(uint256 i=0; i < payloads.length;++i){
            sendTransaction(payloads[i], zrWalletIndex, chainId);
        }
    }

    /**
     * Send a transaction from a managed wallet with the given params
     *
     * @param transaction The transaction to execute
     * @param zrWalletIndex The wallet to execute the transaction
     * @param chainId The chain where the transaction should be executed
     */
    function sendTransaction(TransactionParams memory transaction, 
        uint256 zrWalletIndex, 
        bytes32 chainId
    ) private {
        uint256 nonce = _nonce[zrWalletIndex][chainId];
        bytes memory data = rlpEncodeData(transaction.data);
        bytes memory rlpTransactionData = rlpEncodeTransaction(
            nonce,
            transaction.gasPrice,
            transaction.gasLimit,
            transaction.to,
            transaction.value,
            data
        );

        reqSignForTx(
            EVMWalletType,
            zrWalletIndex,
            chainId,
            rlpTransactionData,
            true
        );

        nonce++;

        _nonce[zrWalletIndex][chainId] = nonce;
    }

    receive() external payable {}
}