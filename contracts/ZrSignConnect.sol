// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.12;

import './lib/zr/RLPWriter.sol';
import './interfaces/zr/IZrSign.sol';
import './interfaces/zr/ISign.sol';

import 'hardhat/console.sol';

// Abstract contract for zrSIgn connections
abstract contract ZrSignConnect {
    // Use the RLPWriter library for various types
    using RLPWriter for address;
    using RLPWriter for uint256;
    using RLPWriter for bytes;
    using RLPWriter for bytes[];

    // The wallet type for EVM-based wallets
    bytes32 internal constant EVMWalletType = 0xe146c2986893c43af5ff396310220be92058fb9f4ce76b929b80ef0d5307100a;

    uint8 private constant WALLET_OPTIONS = 1;

    IZrSign immutable _zrSign;

    constructor(address zrSign){
        _zrSign = IZrSign(zrSign);
    }

    // Request a new EVM wallet
    // This function uses the ZrSign contract to request a new public key for the EVM wallet type
    function requestNewEVMWallet() internal virtual returns (uint256 walletIndex) {
        (,,uint256 _fee) = _zrSign.estimateFee(WALLET_OPTIONS, 0);
        
        walletIndex = _zrSign.getZrKeys(EVMWalletType, address(this)).length;        

        // Prepare the parameters for the key request
        SignTypes.ZrKeyReqParams memory params = SignTypes.ZrKeyReqParams({
            walletTypeId: EVMWalletType,
            options: WALLET_OPTIONS
        });

        _zrSign.zrKeyReq{value: _fee}(params);
    }

    // Request a signature for a specific hash
    // This function uses the ZrSign contract to request a signature for a specific hash
    // Parameters:
    // - walletTypeId: The ID of the wallet type associated with the hash
    // - fromAccountIndex: The index of the public key to be used for signing
    // - dstChainId: The ID of the destination chain
    // - payloadHash: The hash of the payload to be signed
    function reqSignForHash(
        bytes32 walletTypeId,
        uint256 walletIndex,
        bytes32 dstChainId,
        bytes32 payloadHash
    ) internal virtual {
        (,,uint256 _fee) = _zrSign.estimateFee(WALLET_OPTIONS, 0);

        SignTypes.ZrSignParams memory params = SignTypes.ZrSignParams({
            walletTypeId: walletTypeId,
            walletIndex: walletIndex,
            dstChainId: dstChainId,
            payload: abi.encodePacked(payloadHash),
            broadcast: false
        });

        _zrSign.zrSignHash{value: _fee}(params);
    }

    // Request a signature for a specific data payload
    // This function uses the ZrSign contract to request a signature for a specific data payload
    // Parameters:
    // - walletTypeId: The ID of the wallet type associated with the data payload
    // - fromAccountIndex: The index of the public key to be used for signing
    // - dstChainId: The ID of the destination chain
    // - payload: The data payload to be signed
    function reqSignForData(
        bytes32 walletTypeId,
        uint256 walletIndex,
        bytes32 dstChainId,
        bytes memory payload
    ) internal virtual {
        (,,uint256 _fee) = _zrSign.estimateFee(WALLET_OPTIONS, 0);

        SignTypes.ZrSignParams memory params = SignTypes.ZrSignParams({
            walletTypeId: walletTypeId,
            walletIndex: walletIndex,
            dstChainId: dstChainId,
            payload: payload,
            broadcast: false
        });
        _zrSign.zrSignData{value: _fee}(params);
    }

    // Request a signature for a transaction
    // This function uses the zrSIgn contract to request a signature for a transaction
    // Parameters:
    // - walletTypeId: The ID of the wallet type associated with the transaction
    // - fromAccountIndex: The index of the account from which the transaction will be sent
    // - chainId: The ID of the chain on which the transaction will be executed
    // - payload: The RLP-encoded transaction data
    // - broadcast: A flag indicating whether the transaction should be broadcasted immediately
    function reqSignForTx(
        bytes32 walletTypeId,
        uint256 walletIndex,
        bytes32 dstChainId,
        bytes memory payload,
        bool broadcast
    ) internal virtual {
        (,,uint256 _fee) = _zrSign.estimateFee(WALLET_OPTIONS, 0);

        SignTypes.ZrSignParams memory params = SignTypes.ZrSignParams({
            walletTypeId: walletTypeId,
            walletIndex: walletIndex,
            dstChainId: dstChainId,
            payload: payload,
            broadcast: broadcast
        });

        _zrSign.zrSignTx{value: _fee}(params);
    }

    // Get an EVM wallet associated with this contract by index
    // This function uses the zrSIgn contract to get a specific EVM wallet that belongs to this contract, specified by an index
    // Parameter:
    // - index: The index of the EVM wallet to be retrieved
    function getEVMWallet(address owner, uint256 index) internal returns (string memory wallet, bool ok) {
        bytes memory args = abi.encodeWithSelector(ISign.getZrKey.selector, EVMWalletType, owner, index);

        (bool success, bytes memory data) = address(_zrSign).call(args);

        if(success){
            console.logBytes(data);

            wallet = abi.decode(data, (string));
        }

        return (wallet, success);
    }

    // Encode data using RLP
    // This function uses the RLPWriter library to encode data into RLP format
    function rlpEncodeData(bytes memory data)
        internal
        virtual
        returns (bytes memory)
    {
        return data.writeBytes();
    }

    // Encode a transaction using RLP
    // This function uses the RLPWriter library to encode a transaction into RLP format
    function rlpEncodeTransaction(
        uint256 nonce,
        uint256 gasPrice,
        uint256 gasLimit,
        address to,
        uint256 value,
        bytes memory data
    ) internal virtual returns (bytes memory) {
        bytes memory nb = nonce.writeUint();
        bytes memory gp = gasPrice.writeUint();
        bytes memory gl = gasLimit.writeUint();
        bytes memory t = to.writeAddress();
        bytes memory v = value.writeUint();
        return _encodeTransaction(nb, gp, gl, t, v, data);
    }

    // Helper function to encode a transaction
    // This function is used by the rlpEncodeTransaction function to encode a transaction into RLP format
    function _encodeTransaction(
        bytes memory nonce,
        bytes memory gasPrice,
        bytes memory gasLimit,
        bytes memory to,
        bytes memory value,
        bytes memory data
    ) internal pure returns (bytes memory) {
        bytes memory zb = uint256(0).writeUint();
        bytes[] memory payload = new bytes[](9);
        payload[0] = nonce;
        payload[1] = gasPrice;
        payload[2] = gasLimit;
        payload[3] = to;
        payload[4] = value;
        payload[5] = data;
        payload[6] = zb;
        payload[7] = zb;
        payload[8] = zb;
        return payload.writeList();
    }
}