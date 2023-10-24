// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

struct Product {
    address merchant;
    bytes32 metadata; // metadata like subscriptionId, dmerchant domain, etc.
    address token;
    uint256 amount;
    uint256 period;
    uint256 freeTrialLength;
    uint256 paymentPeriod; // How many seconds there is to make a payment
}

struct Subscription {
    bytes32 productHash;
    address user;
    uint256 start;
    uint256 paymentsMade; // 1 - one payment has been made, 2 - two payments have been made, etc.
    bool terminated;
    address initiator; // who is allowed to initiate payments
}

contract BeaverRouter {
    address _owner;
    uint256 _fee;

    constructor(address owner, uint256 fee) {
        _owner = owner;
        _fee = fee;
    }

    event ProductCreated(
        bytes32 indexed productHash,
        address indexed merchant,
        bytes32 indexed metadata,
        address token,
        uint256 amount,
        uint256 period,
        uint256 freeTrialLength,
        uint256 paymentPeriod
    );

    event SubscriptionStarted(
        bytes32 indexed subscriptionHash,
        bytes32 indexed productHash,
        address indexed user,
        uint256 start,
        address initiator
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
        bytes32 indexed subscriptionHash,
        address indexed newInitiator,
        address indexed changedBy,
        address oldInitiator
    );

    mapping(bytes32 => Product) public products;
    mapping(bytes32 => Subscription) public subscriptions;
    mapping(address => mapping(address => uint256)) public txCompensations; // Compensation for gas fees spent by initiator. token address => merchant address => amount.
    mapping(address => uint256) public earnedFees; // token address => amount
    mapping(bytes32 => uint64) public productNonce; // uint64 is the same as Ethereum's nonce for transactions

    function createProduct(
        address merchant,
        bytes32 metadata,
        address token,
        uint256 amount,
        uint256 period,
        uint256 freeTrialLength,
        uint256 paymentPeriod
    ) external returns (bytes32 productHash) {
        productHash = keccak256(
            abi.encodePacked(
                merchant,
                metadata,
                token,
                amount,
                period,
                freeTrialLength,
                paymentPeriod
            )
        );

        products[productHash] = Product(
            merchant,
            metadata,
            token,
            amount,
            period,
            freeTrialLength,
            paymentPeriod
        );

        emit ProductCreated(
            productHash,
            merchant,
            metadata,
            token,
            amount,
            period,
            freeTrialLength,
            paymentPeriod
        );
    }

    function startSubscription(
        bytes32 productHash,
        address initiator
    ) external returns (bytes32 subscriptionHash) {
        console.log("Sender is");
        console.logAddress(msg.sender);
        // Subscription hash is a unique identifier for every subscription.
        Product storage product = products[productHash];

        require(
            product.merchant != address(0),
            "BeaverRouter: this product doesn't exist"
        );

        subscriptionHash = keccak256(
            abi.encodePacked(
                block.chainid,
                productHash,
                productNonce[productHash]++
            )
        );

        uint256 start = block.timestamp + product.freeTrialLength;
        subscriptions[subscriptionHash] = Subscription(
            productHash,
            msg.sender,
            start,
            0,
            false,
            initiator
        );

        emit SubscriptionStarted(
            subscriptionHash,
            productHash,
            msg.sender,
            start,
            initiator
        );

        if (product.freeTrialLength == 0) this.makePayment(subscriptionHash, 0);
    }

    function createProductAndStartSubscription(
        address merchant,
        bytes32 metadata,
        address token,
        uint256 amount,
        uint256 period,
        uint256 freeTrialLength,
        uint256 paymentPeriod,
        address initiator
    ) external returns (bytes32 subscriptionHash) {
        bytes32 productHash = this.createProduct(
            merchant,
            metadata,
            token,
            amount,
            period,
            freeTrialLength,
            paymentPeriod
        );
        subscriptionHash = this.startSubscription(productHash, initiator);
    }

    function makePayment(
        bytes32 subscriptionHash,
        uint256 compensation
    ) external returns (bool) {
        Subscription storage sub = subscriptions[subscriptionHash];
        Product storage product = products[sub.productHash];

        require(
            msg.sender == address(this) || msg.sender == sub.initiator,
            "BeaverRouter: only initiator is allowed to initiate payments"
        );

        require(
            !sub.terminated,
            "BeaverRouter: subscription has been terminated"
        );

        uint256 paymentTimestamp = sub.start +
            sub.paymentsMade *
            product.period;

        require(
            block.timestamp >= paymentTimestamp,
            "BeaverRouter: too early to make payment"
        );

        require(
            block.timestamp < paymentTimestamp + product.paymentPeriod,
            "BeaverRouter: subscription has expired"
        );

        uint256 fee = (product.amount * _fee) / (10 ** 18);
        uint256 toRouter = compensation + fee;

        require(
            toRouter < product.amount, // prevent initiators from making the compensation too high
            "BeaverRouter: too much to send to the router"
        );

        uint256 toMerchant = product.amount - toRouter;

        IERC20(product.token).transferFrom(
            sub.user,
            product.merchant,
            toMerchant
        );
        IERC20(product.token).transferFrom(sub.user, address(this), toRouter);

        txCompensations[product.token][sub.initiator] += compensation;
        earnedFees[product.token] += fee;

        sub.paymentsMade += 1;
        emit PaymentMade(subscriptionHash, sub.paymentsMade);
        return true;
    }

    function terminateSubscription(
        bytes32 subscriptionHash
    ) external returns (bool) {
        Subscription storage sub = subscriptions[subscriptionHash];
        Product storage product = products[sub.productHash];

        require(
            msg.sender == sub.user || msg.sender == product.merchant,
            "BeaverRouter: only the user and the merchant can terminate the subscription"
        );

        sub.terminated = true;
        emit SubscriptionTerminated(subscriptionHash, msg.sender);
        return true;
    }

    function changeInitiator(
        bytes32 subscriptionHash,
        address newInitiator
    ) external returns (bool) {
        Subscription storage sub = subscriptions[subscriptionHash];
        Product storage product = products[sub.productHash];

        require(
            msg.sender == sub.initiator || msg.sender == product.merchant,
            "BeaverRouter: only current initiator and merchant are allowed to change initiator."
        );

        emit InitiatorChanged(
            subscriptionHash,
            newInitiator,
            msg.sender,
            sub.initiator
        );
        sub.initiator = newInitiator;
        return true;
    }

    function claimCompensation(
        address token,
        address to
    ) external returns (bool) {
        uint256 amount = txCompensations[token][msg.sender];

        require(
            amount > 0,
            "BeaverRouter: can only claim non-zero compensation"
        );

        IERC20(token).transfer(to, amount);

        txCompensations[token][msg.sender] = 0;
        return true;
    }

    function claimFees(address token, address to) external returns (bool) {
        require(
            msg.sender == _owner,
            "BeaverRouter: fees can only be claimed by the owner"
        );

        uint256 amount = earnedFees[token];

        require(
            amount > 0,
            "BeaverRouter: can only claim non-zero earned fees"
        );

        IERC20(token).transfer(to, amount);

        earnedFees[token] = 0;
        return true;
    }

    function changeOwner(address newOwner) external returns (bool) {
        require(
            msg.sender == _owner,
            "BeaverRouter: only owner can change the owner"
        );

        _owner = newOwner;

        return true;
    }

    function changeFee(uint256 newFee) external returns (bool) {
        require(
            msg.sender == _owner,
            "BeaverRouter: only owner can change the owner"
        );

        _fee = newFee;

        return true;
    }
}
