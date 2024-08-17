// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.12;

import './models/Account.sol';
import './models/TransactionParams.sol';

import './lib/zr/SignTypes.sol';

import './interfaces/zr/IZrSign.sol';
import './interfaces/IERC20.sol';

import './ZrSignConnect.sol';

contract AccountManager is ZrSignConnect {

    // contract admin
    address private immutable _admin;

    // mapping of users to managed accounts
    mapping(address => Account) private _accounts;
    mapping(address => bool) private _activeAccounts;

    // mapping of managed accounts to nonces on various chains
    // zrWalletIndex => (chainId => nonce)
    mapping(uint256 => mapping(bytes32 => uint256)) private _nonce;

    event NewTransaction(address indexed from, uint256 indexed nonce, uint256 id, string chainId, bytes32 txHash);

    constructor(address zrSign) 
        ZrSignConnect(zrSign) {

        _admin = msg.sender;
    }

    /**
     * @dev Create a wallet for the gas provider 
     */
    function createGasProvider() public {
        require(msg.sender == _admin, "unauthorized");

        _createAccount(address(this), new bytes(0));
    }

    /**
     * @dev Get the EOA address of the gas provider for this account. This account is responsible
     * for sending gas to dependent accounts and must always be funded.
     */
    function getGasProvider() public view returns (address, bool) {
        Account memory account = getAccount(address(this));

        return (account.eoa, account.created);
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

        if(!_activeAccounts[owner]){ return account; }

        string memory wallet;

        (wallet, account.created) = getEVMWallet(account.zrWalletIndex);

        account.eoa = address(bytes20(bytes(wallet)));

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
    function execute(TransactionParams[] memory payloads, 
        uint256 zrWalletIndex,
        bytes memory updatedAccountData,
        bool manageGas
    ) public payable {
        Account memory sender = getAccount(msg.sender);

        require(zrWalletIndex == sender.zrWalletIndex, "unauthorized");

        uint256 gas = 0;

        for(uint256 i=0; i < payloads.length;++i){
            TransactionParams memory txParam = payloads[i];

            if(manageGas){
                uint256 txGas = txParam.gasLimit * txParam.gasPrice;

                _sendGas(txParam.id, sender.eoa, txGas, txParam.gasPrice, txParam.chainId);

                gas += txGas; 
            }
            
            _sendTransaction(payloads[i], zrWalletIndex, msg.sender, sender.eoa);
        }

        if(manageGas){
            require(msg.value >= gas, "insufficient gas");
        }

        if(updatedAccountData.length > 0){
            setAccountData(updatedAccountData);
        }
    } 

    /**
     * @dev Send gas gas required to execute a transaction to the EOA account executor. This needs to be completed
     * before the managed account EOA executes txs, otherwise it may run out of gas.
     */
    function _sendGas(uint256 id, address to, uint256 amount, uint256 gasPrice, string memory chainId) private {
        TransactionParams memory transaction = TransactionParams({ 
            id: id,
            to: to, 
            data: new bytes(0),
            gasPrice: gasPrice,
            gasLimit: 100000,
            value: amount,
            chainId: chainId
        });

        Account memory account = getAccount(address(this));

        require(account.created, "gas provider is not configured");

        _sendTransaction(transaction, account.zrWalletIndex, address(this), account.eoa);
    }

    /**
     * Send a transaction from a managed wallet with the given params
     *
     * @param transaction The transaction to execute
     * @param zrWalletIndex The wallet to execute the transaction
     * @param sender The address of the wallet owner the tx is being sent on behalf of
     */
    function _sendTransaction(TransactionParams memory transaction, 
        uint256 zrWalletIndex,
        address sender,
        address eoa
    ) private {
        bytes32 chainId = _getHashedChainId(transaction.chainId);
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

        if(nonce == 0){ 
            _accounts[sender].active = true;
        }

        bytes32 txHash = keccak256(rlpTransactionData);

        emit NewTransaction(eoa, nonce, transaction.id, transaction.chainId, txHash);

        nonce++;

        _nonce[zrWalletIndex][chainId] = nonce;
    }

    receive() external payable {}
}