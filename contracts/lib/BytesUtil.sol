// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library BytesUtil {

    function unpackAmount(bytes memory data, uint256 position) internal pure returns (uint256 amount, uint256 offset) {
        uint8 amount0Length = extractUint8(data, position);

        offset = 1;
        
        amount = convertBytesToUint256(data, offset, amount0Length);

        offset += amount0Length;
    }

    function formatAmount(uint256 amount) internal pure returns (bytes memory) {
        bytes memory value;

        if (amount <= type(uint8).max) {
            value = abi.encodePacked(uint8(amount));
        } else if (amount <= type(uint16).max) {
            value = abi.encodePacked(uint16(amount));
        } else if (amount <= type(uint24).max) {
            value = abi.encodePacked(uint24(amount));
        } else if (amount <= type(uint32).max) {
            value = abi.encodePacked(uint32(amount));
        } else if (amount <= type(uint40).max) {
            value = abi.encodePacked(uint40(amount));
        } else if (amount <= type(uint48).max) {
            value = abi.encodePacked(uint48(amount));
        } else if (amount <= type(uint56).max) {
            value = abi.encodePacked(uint56(amount));
        } else if (amount <= type(uint64).max) {
            value = abi.encodePacked(uint64(amount));
        } else if (amount <= type(uint72).max) {
            value = abi.encodePacked(uint72(amount));
        } else if (amount <= type(uint80).max) {
            value = abi.encodePacked(uint80(amount));
        } else if (amount <= type(uint88).max) {
            value = abi.encodePacked(uint88(amount));
        } else if (amount <= type(uint96).max) {
            value = abi.encodePacked(uint96(amount));
        } else if (amount <= type(uint128).max) {
            value = abi.encodePacked(uint128(amount));
        } else {
            value = abi.encodePacked(amount);
        }

        return abi.encodePacked(uint8(value.length), value);
    }

    function convertBytesToUint256(bytes memory input, uint256 start, uint256 length) internal pure returns (uint256 result) {
        bytes memory data = new bytes(0);

        if(length > 0){
            data = extract(input, start, start + length-1);
        }
        

        bytes memory pre = new bytes(32-data.length);
        bytes memory combined = concat(pre, data);

        return uint256(convertBytesToBytes32(combined));
    }

    function convertBytes32ToBytes(bytes32 value) internal pure returns (bytes memory) {
        bytes memory result = new bytes(32);
        assembly {
            mstore(add(result, 32), value)
        }
        return result;
    }

    function convertBytesToBytes32(bytes memory value) internal pure returns (bytes32) {
        bytes32 result;
        if (value.length == 0) {
            return result;
        }

        assembly {
            result := mload(add(value, 32))
        }
        return result;
    }

    function extractBytes32(bytes memory input, uint256 start) internal pure returns (bytes32) {
        bytes memory extractedBytes = extract(input, start, start + 31);


        bytes32 extractedValue;
        assembly {
            extractedValue := mload(add(extractedBytes, 32))
        }

        return extractedValue;
    }

    function extractBytes4(bytes memory input, uint256 start) internal pure returns (bytes4) {
        bytes memory extractedBytes = extract(input, start, start + 3);


        bytes4 extractedValue;
        assembly {
            extractedValue := mload(add(extractedBytes, 32))
        }

        return extractedValue;
    }

    function extractAddress(bytes memory input, uint256 start) internal pure returns (address) {
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(input, 0x20), start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function extractAddresses(bytes memory data, uint256 start) internal pure returns (address[] memory) {
        uint256 dataLength = data.length;

        // Calculate the number of addresses based on the remaining bytes
        uint256 remainingBytes = dataLength - start;

        uint256 numAddresses = remainingBytes / 20;
        address[] memory addresses = new address[](numAddresses);

        uint256 currentPos = start;

        for (uint256 i = 0; i < numAddresses; i++) {
            addresses[i] = extractAddress(data, currentPos);
            currentPos += 20;
        }

        return addresses;
    }

    function extractUint160(bytes memory input, uint256 start) internal pure returns (uint160) {
        uint160 tempUint;

        assembly {
            tempUint := mload(add(add(input, 0x14), start))
        }

        return tempUint;
    }

    function extract20Bytes(bytes memory input, uint256 start) internal pure returns(bytes memory output) {
        output = extract(input, start, start+19);
    }

    function extractUint128Amounts(bytes memory input, uint256 start) internal pure returns (uint128[] memory) {
        uint256 dataLength = input.length;

        // Calculate the number of addresses based on the remaining bytes
        uint256 remainingBytes = dataLength - start;

        uint256 numAmounts = remainingBytes / 16;
        uint128[] memory amounts = new uint128[](numAmounts);

        uint256 currentPos = start;

        for (uint256 i = 0; i < numAmounts; i++) {
            amounts[i] = extractUint128(input, currentPos);
            currentPos += 16;
        }

        return amounts;

    }
    function extractUint128(bytes memory input, uint256 start) internal pure returns (uint128) {
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(input, 0x10), start))
        }

        return tempUint;
    }

    function extractUint256(bytes memory input, uint256 start) internal pure returns (uint256) {
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(input, 0x20), start))
        }

        return tempUint;
    }

    function extractUint32(bytes memory input, uint256 start) internal pure returns (uint32) {
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(input, 0x4), start))
        }

        return tempUint;
    }

    function extractUint24(bytes memory data, uint256 start) internal pure returns (uint24) {
        bytes memory extractedBytes = extract(data, start, start + 2); // Assuming uint24 occupies 3 bytes

        uint24 value = uint24(uint8(extractedBytes[2])) + uint24(uint8(extractedBytes[1])) * 256 + uint24(uint8(extractedBytes[0])) * 65536;
        
        return value;
    }

    function extractUint16(bytes memory data, uint256 start) internal pure returns (uint16) {
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(data, 0x2), start))
        }

        return tempUint;
    }

    function extractUint8(bytes memory data, uint256 start) internal pure returns (uint8) {
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(data, 0x1), start))
        }

        return tempUint;
    }

    function extractBool(bytes memory input, uint256 start) internal pure returns (bool) {
        uint8 value = uint8(input[start]);

        require(value <= 1, "invalid boolean value");

        return value == 1;
    }

    function extractByLength(bytes memory input, uint256 start, uint256 length) internal pure returns (bytes memory) {
        return extract(input, start, start+length-1);
    }

    function extract(bytes memory input, uint256 start, uint256 end) internal pure returns (bytes memory){
        uint256 length = (end - start)+1;

        bytes memory tempBytes;

        assembly {
            switch iszero(length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let _end := add(mc, length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(input, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, _end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }


        return tempBytes;
    }

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }
}