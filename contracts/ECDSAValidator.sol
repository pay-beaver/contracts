// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/ECDSA.sol";
import "./KernelHelper.sol";
import "./IKernelValidator.sol";
import "./KernelTypes.sol";
import "hardhat/console.sol";
import "solady/src/utils/EIP712.sol";

struct ECDSAValidatorStorage {
    address owner;
    mapping(uint192 => bool) stoppedSubscriptions; // A set of nonce keys that should no longer be accepted because the user has cancelled their subscription on these keys
}

contract ECDSAValidator is IKernelValidator, EIP712 {
    event OwnerChanged(
        address indexed kernel,
        address indexed oldOwner,
        address indexed newOwner
    );

    mapping(address => ECDSAValidatorStorage) public ecdsaValidatorStorage;

    function disable(bytes calldata) external payable override {
        delete ecdsaValidatorStorage[msg.sender];
    }

    function enable(bytes calldata _data) external payable override {
        address owner = address(bytes20(_data[0:20]));
        address oldOwner = ecdsaValidatorStorage[msg.sender].owner;
        ecdsaValidatorStorage[msg.sender].owner = owner;
        emit OwnerChanged(msg.sender, oldOwner, owner);
    }

    function validateUserOp(
        UserOperation calldata _userOp,
        bytes32 _userOpHash,
        uint256
    ) external payable override returns (ValidationData validationData) {
        address owner = ecdsaValidatorStorage[_userOp.sender].owner;
        bytes32 hash = ECDSA.toEthSignedMessageHash(_userOpHash);
        if (owner == ECDSA.recover(hash, _userOp.signature)) {
            return ValidationData.wrap(0);
        }
        if (owner != ECDSA.recover(_userOpHash, _userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
    }

    // function validateSignature(
    //     bytes32 hash,
    //     bytes calldata signature
    // ) public view override returns (ValidationData) {
    //     // address owner = ecdsaValidatorStorage[msg.sender].owner;
    //     address owner = 0x93e5d723902C96D6B8af04cA6F26C9a3EA8b3566;
    //     address recovered1 = ECDSA.recover(hash, signature);
    //     console.log("recovered 1", recovered1);
    //     if (owner == recovered1) {
    //         return ValidationData.wrap(0);
    //     }
    //     bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
    //     address recovered2 = ECDSA.recover(ethHash, signature);
    //     console.log("recovered 2", recovered2);
    //     if (owner != recovered2) {
    //         return SIG_VALIDATION_FAILED;
    //     }
    //     return ValidationData.wrap(0);
    // }
    function validateSignature(
        bytes32 hash,
        bytes calldata signature
    ) public view override returns (ValidationData) {
        // address owner = ecdsaValidatorStorage[msg.sender].owner;
        address owner = 0x93e5d723902C96D6B8af04cA6F26C9a3EA8b3566;
        if (owner == ECDSA.recover(hash, signature)) {
            return ValidationData.wrap(0);
        }
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        address recovered = ECDSA.recover(ethHash, signature);
        if (owner != recovered) {
            return SIG_VALIDATION_FAILED;
        }
        return ValidationData.wrap(0);
    }

    function validCaller(
        address _caller,
        bytes calldata
    ) external view override returns (bool) {
        return ecdsaValidatorStorage[msg.sender].owner == _caller;
    }

    function example(bytes4 sig, bytes calldata signature) external view {
        console.log("Hello");
        uint256 cursor = 88;
        uint256 length = uint256(bytes32(signature[56:88])); // this is enableDataLength
        bytes calldata enableData;
        assembly {
            enableData.offset := add(signature.offset, cursor)
            enableData.length := length
            cursor := add(cursor, length) // 88 + enableDataLength
        }
        // length = uint256(bytes32(signature[cursor:cursor + 32])); // this is enableSigLength
        assembly {
            cursor := add(cursor, 32)
        }
        bytes32 keccak = keccak256(
            abi.encode(
                VALIDATOR_APPROVED_STRUCT_HASH,
                bytes4(sig),
                uint256(bytes32(signature[4:36])),
                address(bytes20(signature[36:56])),
                keccak256(enableData)
            )
        );
        console.log("keccak:");
        console.logBytes32(keccak);
        bytes32 enableDigest = _hashTypedData(keccak);
        console.log("enableDigest");
        console.logBytes32(enableDigest);
        console.log("Chain id");
        console.logUint(block.chainid);
    }

    function _domainNameAndVersion()
        internal
        pure
        virtual
        override
        returns (string memory name, string memory version)
    {
        name = "Kernel";
        version = "0.2.1";
    }
}
