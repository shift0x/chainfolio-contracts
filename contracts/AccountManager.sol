// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.12;

import './models/Account.sol';
import './models/TransactionParams.sol';

import './lib/zr/SignTypes.sol';

import './interfaces/zr/IZrSign.sol';
import './interfaces/IERC20.sol';

import './ZrSignConnect.sol';

import 'hardhat/console.sol';

contract AccountManager is ZrSignConnect {

    // mapping of users to managed accounts
    mapping(address => Account) private _accounts;
    mapping(address => bool) private _activeAccounts;

    event NewTransaction(address indexed from, uint256 indexed nonce, string chainId, bytes32 txHash);

    constructor(address zrSign) 
        ZrSignConnect(zrSign) {
    }

    /**
     * @dev Create a new managed account
     * 
     * @param data bytes representing the configuration of the account
     */
    function createAccount(bytes memory data) public {
        _createAccount(msg.sender, data);
    }

    /**
     * @dev Create a new managed account
     * 
     * @param owner address of the owner of the managed account
     * @param data bytes representing the configuration of the account
     */
    function _createAccount(address owner, bytes memory data) private {
        Account memory account = _accounts[owner];

        require(!account.active, "cannot override account in use");

        // create a new wallet with zrSign and store the walletId
        uint256 walletIndex = requestNewEVMWallet();

        // create a new account for the newly created wallet
        _accounts[owner] = Account(walletIndex, data, address(0), false, false);
        _activeAccounts[owner] = true;
    }

    /**
     * @dev Updates a account for the given id
     * 
     * @param data bytes representing the configuration of the account
     */
    function setAccountData(bytes memory data) public {
        _accounts[msg.sender].data = data;
    }

    /**
     * @dev Get the strategies associated with the given account
     *
     * @param owner Account to get strategies for
     */
    function getAccount(address owner) public view returns (Account memory){
        Account memory account = _accounts[owner];

        account.created = _activeAccounts[owner];

        return account;
    }

    /**
     * @dev Get the keccak256 for the given chainId
     *
     * @param chainId Chain identifier
     */
    function _getHashedChainId(string memory chainId) private pure returns (bytes32) {
        string memory str = string.concat("eip155:", chainId);

        return keccak256(abi.encodePacked(str));
    }

    /**
     * @dev Execute transactions on behalf of a given account
     *
     * @param payloads Transactions to execute
     */
    function execute(TransactionParams[] memory payloads) public payable {
        Account memory sender = getAccount(msg.sender);

        for(uint256 i=0; i < payloads.length;++i){
            TransactionParams memory params = payloads[i];

            require(params.zrWalletIndex == sender.zrWalletIndex, "unauthorized");

            _sendTransaction(params);
        }
    } 

    /**
     * Send a transaction from a managed wallet with the given params
     *
     * @param transaction The transaction to execute
     */
    function _sendTransaction(TransactionParams memory transaction) private {
        bytes32 chainId = _getHashedChainId(transaction.chainId);
        bytes memory data = rlpEncodeData(transaction.data);
        bytes memory rlpTransactionData = rlpEncodeTransaction(
            transaction.nonce,
            transaction.gasPrice,
            transaction.gasLimit,
            transaction.to,
            transaction.value,
            data
        );

        reqSignForTx(
            EVMWalletType,
            transaction.zrWalletIndex,
            chainId,
            rlpTransactionData,
            true
        );

        if(transaction.nonce == 0){ 
            _accounts[msg.sender].active = true;
        }

        bytes32 txHash = keccak256(rlpTransactionData);

        emit NewTransaction(transaction.eoa, transaction.nonce, transaction.chainId, txHash);
    }

    receive() external payable {}
}