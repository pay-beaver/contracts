// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Subscription {
    address user;
    address merchant;
    string merchantDomain;
    bytes32 nonce;
    address token;
    uint256 amount;
    uint256 period;
    uint256 start;
    uint256 paymentPeriod; // How many seconds there is to make a payment
    uint256 paymentsMade; // 1 - one payment has been made, 2 - two payments have been made, etc.
    bool terminated;
}

contract BeaverRouter {
    event SubscriptionStarted(
        bytes32 indexed subscriptionHash,
        address indexed user,
        address indexed merchant,
        string merchantDomain,
        bytes32 nonce,
        address token,
        uint256 amount,
        uint256 period,
        uint256 start,
        uint256 paymentPeriod
    );

    event PaymentMade(
        bytes32 indexed subscriptionHash,
        uint256 indexed paymentNumber
    );

    event SubscriptionTerminated(bytes32 indexed subscriptionHash);

    mapping(bytes32 => Subscription) public subscriptions;

    function startSubscription(
        address merchant,
        string calldata merchantDomain,
        bytes32 nonce,
        address token,
        uint256 amount,
        uint256 period,
        uint256 freeTrialLength,
        uint256 paymentPeriod // How many seconds there is to make a payment
    ) external returns (bytes32 subscriptionHash) {
        subscriptionHash = keccak256(
            abi.encodePacked(
                block.chainid,
                msg.sender,
                merchant,
                merchantDomain,
                nonce,
                token,
                amount,
                period,
                freeTrialLength,
                paymentPeriod
            )
        );

        require(
            subscriptions[subscriptionHash].user == address(0),
            "BeaverRouter: subscription already exists"
        );

        uint256 start = block.timestamp + freeTrialLength;
        subscriptions[subscriptionHash] = Subscription(
            msg.sender,
            merchant,
            merchantDomain,
            nonce,
            token,
            amount,
            period,
            start,
            paymentPeriod,
            0,
            false
        );

        emit SubscriptionStarted(
            subscriptionHash,
            msg.sender,
            merchant,
            merchantDomain,
            nonce,
            token,
            amount,
            period,
            start,
            paymentPeriod
        );

        if (freeTrialLength == 0) this.makePayment(subscriptionHash);
    }

    // Anybody can call this function to execute a pending payment.
    function makePayment(bytes32 subscriptionHash) external returns (bool) {
        Subscription storage sub = subscriptions[subscriptionHash];

        require(
            !sub.terminated,
            "BeaverRouter: subscription has been terminated"
        );

        uint256 paymentTimestamp = sub.start + sub.paymentsMade * sub.period;

        require(
            block.timestamp >= paymentTimestamp,
            "BeaverRouter: too early to make payment"
        );

        require(
            block.timestamp < paymentTimestamp + sub.paymentPeriod,
            "BeaverRouter: subscription has expired"
        );

        IERC20(sub.token).transferFrom(sub.user, sub.merchant, sub.amount);
        sub.paymentsMade += 1;

        emit PaymentMade(subscriptionHash, sub.paymentsMade);
        return true;
    }

    function terminateSubscription(
        bytes32 subscriptionHash
    ) external returns (bool) {
        Subscription storage sub = subscriptions[subscriptionHash];

        require(
            msg.sender == sub.user,
            "BeaverRouter: only the user can terminate the subscription"
        );

        sub.terminated = true;
        emit SubscriptionTerminated(subscriptionHash);
        return true;
    }
}
