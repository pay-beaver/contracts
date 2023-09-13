// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.19;

import "solady/src/utils/ECDSA.sol";
import "./KernelHelper.sol";
import "./IKernelValidator.sol";
import "./KernelTypes.sol";

struct SubscriptionValidatorStorage {
    address owner;
}

/**
 * Returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and
 * parsed by `_parseValidationData`.
 * @param aggregator  - address(0) - The account validated the signature by itself.
 *                      address(1) - The account failed to validate the signature.
 *                      otherwise - This is an address of a signature aggregator that must
 *                                  be used to validate the signature.
 * @param validAfter  - This UserOp is valid only after this timestamp.
 * @param validaUntil - This UserOp is valid only up to this timestamp.
 */
struct EntryPointValidationData {
    address aggregator;
    uint48 validAfter;
    uint48 validUntil;
}

/**
 * Helper to pack the return value for validateUserOp.
 * @param data - The ValidationData to pack.
 */
function _packValidationData(
    EntryPointValidationData memory data
) pure returns (uint256) {
    return
        uint160(data.aggregator) |
        (uint256(data.validUntil) << 160) |
        (uint256(data.validAfter) << (160 + 48));
}

contract SubscriptionValidator is IKernelValidator {
    event OwnerChanged(
        address indexed kernel,
        address indexed oldOwner,
        address indexed newOwner
    );
    event SubscriptionTerminated(
        address indexed user,
        uint192 indexed subscriptionId
    );

    mapping(address => SubscriptionValidatorStorage)
        public subscriptionValidatorStorage;

    mapping(uint192 => mapping(address => bool)) public terminatedSubscriptions;

    function disable(bytes calldata) external payable override {
        delete subscriptionValidatorStorage[msg.sender];
    }

    function terminateSubscription(uint192 _subscriptionId) external {
        terminatedSubscriptions[_subscriptionId][msg.sender] = true;
        emit SubscriptionTerminated(msg.sender, _subscriptionId);
    }

    function enable(bytes calldata _data) external payable override {
        address owner = address(bytes20(_data[0:20]));
        address oldOwner = subscriptionValidatorStorage[msg.sender].owner;
        subscriptionValidatorStorage[msg.sender].owner = owner;
        emit OwnerChanged(msg.sender, oldOwner, owner);
    }

    function validateUserOp(
        UserOperation calldata _userOp,
        bytes32 _userOpHash,
        uint256
    ) external payable override returns (ValidationData validationData) {
        bytes6 validAfterBytes = bytes6(_userOp.signature[:6]);
        bytes calldata ECDSASignature = _userOp.signature[6:];
        bytes32 fullUserOpHash = keccak256(
            abi.encodePacked(_userOpHash, validAfterBytes)
        );

        address owner = subscriptionValidatorStorage[_userOp.sender].owner;
        bytes32 hash = ECDSA.toEthSignedMessageHash(fullUserOpHash);
        address recovered1 = ECDSA.recover(hash, ECDSASignature);
        address recovered2 = ECDSA.recover(fullUserOpHash, ECDSASignature);
        if (owner != recovered1 && owner != recovered2) {
            return SIG_VALIDATION_FAILED;
        }

        uint192 subscriptionId = uint192(_userOp.nonce >> 64);
        require(
            !terminatedSubscriptions[subscriptionId][_userOp.sender],
            "SubscriptionValidator: subscription is terminated"
        );

        return
            ValidationData.wrap(
                _packValidationData(
                    EntryPointValidationData(
                        0x0000000000000000000000000000000000000000,
                        uint48(validAfterBytes),
                        0
                    )
                )
            );
    }

    function validateSignature(
        bytes32 hash,
        bytes calldata signature
    ) public view override returns (ValidationData) {
        address owner = subscriptionValidatorStorage[msg.sender].owner;
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
        return subscriptionValidatorStorage[msg.sender].owner == _caller;
    }
}
