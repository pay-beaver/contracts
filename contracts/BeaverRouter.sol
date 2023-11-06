// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BeaverRouter {
    address internal _owner;
    address internal _defaultInitiator;
    bool internal _frozen;

    constructor(address owner, address defaultInitiator) {
        _owner = owner;
        _defaultInitiator = defaultInitiator;
    }

    // It's ugly, but the order of variables in the Product struct doesn't match
    // the order in other places, because we pack the variables here.
    struct Product {
        uint256 amount;
        address token;
        uint40 period;
        uint40 freeTrialLength;
        uint40 paymentPeriod; // How many seconds there is to make a payment
        address merchant;
        bytes32 productMetadata; // product metadata like product name
    }

    struct Subscription {
        bytes32 productHash;
        address user;
        uint40 start;
        uint48 paymentsMade; // 1 - one payment has been made, 2 - two payments have been made, etc.
        bool terminated;
        bytes32 subscriptionMetadata; // subscription metadata like subscriptionId, userId
    }

    struct MerchantSettings {
        address initiator;
    }

    event ProductCreated(
        bytes32 indexed productHash,
        address indexed merchant,
        address indexed token,
        uint256 amount,
        uint256 period,
        uint256 freeTrialLength,
        uint256 paymentPeriod,
        bytes32 productMetadata
    );

    event SubscriptionStarted(
        bytes32 indexed subscriptionHash,
        bytes32 indexed productHash,
        address indexed user,
        uint256 start,
        bytes32 subscriptionMetadata
    );

    event PaymentMade(
        bytes32 indexed subscriptionHash,
        uint256 indexed paymentNumber
    );

    event SubscriptionTerminated(
        bytes32 indexed subscriptionHash,
        address indexed terminatedBy
    );

    event InitiatorChanged(
        address indexed merchant,
        address indexed newInitiator,
        address indexed oldInitiator,
        address changedBy
    );

    event OwnerChanged(address indexed newOwner, address indexed oldOwner);

    event DefaultInitiatorChanged(
        address indexed newDefaultInitiator,
        address indexed oldDefaultInitiator
    );

    event Froze();
    event Unfroze();

    mapping(bytes32 => Product) public products;
    mapping(bytes32 => Subscription) public subscriptions;
    mapping(bytes32 => uint256) public productNonce;
    mapping(address => MerchantSettings) public merchantSettings;

    function createProductIfDoesntExist(
        address merchant,
        address token,
        uint256 amount,
        uint40 period,
        uint40 freeTrialLength,
        uint40 paymentPeriod,
        bytes32 productMetadata
    ) external returns (bytes32 productHash) {
        productHash = keccak256(
            abi.encodePacked(
                block.chainid,
                merchant,
                token,
                amount,
                period,
                freeTrialLength,
                paymentPeriod,
                productMetadata
            )
        );

        if (products[productHash].merchant != address(0)) {
            return productHash; // product already exists
        }

        products[productHash] = Product({
            merchant: merchant,
            token: token,
            amount: amount,
            period: period,
            freeTrialLength: freeTrialLength,
            paymentPeriod: paymentPeriod,
            productMetadata: productMetadata
        });

        emit ProductCreated(
            productHash,
            merchant,
            token,
            amount,
            period,
            freeTrialLength,
            paymentPeriod,
            productMetadata
        );
    }

    function _startSubscription(
        bytes32 productHash,
        bytes32 subscriptionMetadata
    ) internal returns (bytes32 subscriptionHash) {
        Product storage product = products[productHash];

        require(product.merchant != address(0), "BR: product does not exist");

        // not hashing chainId since it is already included in productHash.
        subscriptionHash = keccak256(
            abi.encodePacked(productHash, productNonce[productHash]++)
        );

        uint256 start = block.timestamp + product.freeTrialLength;
        subscriptions[subscriptionHash] = Subscription({
            productHash: productHash,
            user: msg.sender,
            start: uint40(start),
            paymentsMade: 0,
            terminated: false,
            subscriptionMetadata: subscriptionMetadata
        });

        emit SubscriptionStarted(
            subscriptionHash,
            productHash,
            msg.sender,
            start,
            subscriptionMetadata
        );

        if (product.freeTrialLength == 0) this.makePayment(subscriptionHash, 0);
    }

    function startSubscription(
        bytes32 productHash,
        bytes32 subscriptionMetadata
    ) external returns (bytes32 subscriptionHash) {
        subscriptionHash = _startSubscription(
            productHash,
            subscriptionMetadata
        );
    }

    function setupEnvironmentAndStartSubscription(
        address merchant,
        address token,
        uint256 amount,
        uint40 period,
        uint40 freeTrialLength,
        uint40 paymentPeriod,
        bytes32 productMetadata,
        bytes32 subscriptionMetadata
    ) external returns (bytes32 subscriptionHash) {
        if (merchantSettings[merchant].initiator == address(0)) {
            this.changeInitiator(merchant, _defaultInitiator);
        }

        bytes32 productHash = this.createProductIfDoesntExist(
            merchant,
            token,
            amount,
            period,
            freeTrialLength,
            paymentPeriod,
            productMetadata
        );

        subscriptionHash = _startSubscription(
            productHash,
            subscriptionMetadata
        );
    }

    function makePayment(
        bytes32 subscriptionHash,
        uint256 compensation
    ) external returns (uint48) {
        require(!_frozen, "BR: router is frozen");

        Subscription storage sub = subscriptions[subscriptionHash];
        Product storage product = products[sub.productHash];
        address initiator = merchantSettings[product.merchant].initiator;

        require(
            msg.sender == address(this) || msg.sender == initiator,
            "BR: not permitted"
        );

        require(!sub.terminated, "BR: subscription is terminated");

        uint256 paymentTimestamp = sub.start +
            sub.paymentsMade *
            product.period;

        require(
            block.timestamp >= paymentTimestamp,
            "BR: too early to make payment"
        );

        require(
            block.timestamp < paymentTimestamp + product.paymentPeriod,
            "BR: subscription has expired"
        );

        // prevent initiators from making the compensation too high
        require(compensation < product.amount, "BR: too high compensation");

        uint256 toMerchant = product.amount - compensation;

        IERC20(product.token).transferFrom(
            sub.user,
            product.merchant,
            toMerchant
        );

        if (compensation > 0) {
            IERC20(product.token).transferFrom(
                sub.user,
                initiator,
                compensation
            );
        }

        sub.paymentsMade += 1;
        emit PaymentMade(subscriptionHash, sub.paymentsMade);

        return sub.paymentsMade;
    }

    function terminateSubscription(bytes32 subscriptionHash) external {
        Subscription storage sub = subscriptions[subscriptionHash];
        Product storage product = products[sub.productHash];

        require(
            msg.sender == sub.user || msg.sender == product.merchant,
            "BR: not permitted"
        );

        sub.terminated = true;
        emit SubscriptionTerminated(subscriptionHash, msg.sender);
    }

    function changeInitiator(address merchant, address newInitiator) external {
        address initiator = merchantSettings[merchant].initiator;

        require(
            msg.sender == initiator ||
                msg.sender == merchant ||
                (initiator == address(0) && newInitiator == _defaultInitiator),
            "BR: not permitted"
        );

        emit InitiatorChanged(merchant, newInitiator, initiator, msg.sender);
        merchantSettings[merchant].initiator = newInitiator;
    }

    function changeOwner(address newOwner) external {
        require(msg.sender == _owner, "BR: not permitted");

        emit OwnerChanged(newOwner, _owner);

        _owner = newOwner;
    }

    function freeze() external {
        require(msg.sender == _owner, "BR: not permitted");

        emit Froze();

        _frozen = true;
    }

    function unfreeze() external {
        require(msg.sender == _owner, "BR: not permitted");

        emit Unfroze();

        _frozen = false;
    }

    function changeDefaultInitiator(address newDefaultInitiator) external {
        require(msg.sender == _owner, "BR: not permitted");

        emit DefaultInitiatorChanged(newDefaultInitiator, _defaultInitiator);

        _defaultInitiator = newDefaultInitiator;
    }
}
