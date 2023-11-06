// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

contract Experiment {
    struct Product {
        uint256 amount;
        address token;
        uint40 period;
        uint40 freeTrialLength;
        uint40 paymentPeriod; // How many seconds there is to make a payment
        address merchant;
        bytes32 productMetadata; // product metadata like product name
    }

    bool lol;
    uint128 a;
    uint128 b;

    mapping(uint256 => Product) products;

    function setAB(uint128 newA, uint128 newB) external returns (bool) {
        a = newA;
        b = newB;

        return true;
    }

    function setLol(bool newLol) external {
        lol = newLol;
    }

    function setProduct(
        uint256 productId,
        address merchant,
        address token,
        uint256 amount,
        uint40 period,
        uint40 freeTrialLength,
        uint40 paymentPeriod,
        bytes32 productMetadata
    ) external {
        products[productId] = Product({
            amount: amount,
            merchant: merchant,
            period: period,
            freeTrialLength: freeTrialLength,
            paymentPeriod: paymentPeriod,
            token: token,
            productMetadata: productMetadata
        });
    }

    function loadProduct(uint256 productId) external {
        Product memory product = products[productId];
        uint40 ts = uint40(block.timestamp);
        bool xyz = ts > block.timestamp;
    }
}
