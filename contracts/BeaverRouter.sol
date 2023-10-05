// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Subscription {
    address user;
    address merchant;
    address token;
    uint256 amount;
    uint256 period;
    uint256 start;
    uint256 paymentsMade; // 1 - one payment has been made, 2 - two payments have been made, etc.
    bool terminated;
}

contract BeaverRouter {
    event SubscriptionStarted(
        bytes32 indexed subscriptionHash,
        address indexed user,
        address indexed merchant,
        address token,
        uint256 amount,
        uint256 period,
        uint256 start
    );

    event PaymentMade(
        bytes32 indexed subscriptionHash,
        uint256 indexed paymentNumber
    );

    event SubscriptionTerminated(bytes32 indexed subscriptionHash);

    mapping(bytes32 => Subscription) public subscriptions;

    function startSubscription(
        address merchant,
        address token,
        uint256 amount,
        uint256 period,
        uint256 start // Separate start is needed to offer a free trial.
    ) external returns (bytes32 subscriptionHash) {
        subscriptionHash = keccak256(
            abi.encodePacked(msg.sender, merchant, token, amount, period, start)
        );

        subscriptions[subscriptionHash] = Subscription(
            msg.sender,
            merchant,
            token,
            amount,
            period,
            start,
            0,
            false
        );

        emit SubscriptionStarted(
            subscriptionHash,
            msg.sender,
            merchant,
            token,
            amount,
            period,
            start
        );

        if (block.timestamp >= start) this.makePayment(subscriptionHash);
    }

    // Anybody can call this function to execute a pending payment.
    function makePayment(bytes32 subscriptionHash) external {
        Subscription storage sub = subscriptions[subscriptionHash];

        require(
            !sub.terminated,
            "BeaverRouter: subscription has been terminated"
        );

        require(
            block.timestamp >= sub.start + sub.paymentsMade * sub.period,
            "BeaverRouter: too early to make payment"
        );

        require(
            block.timestamp < sub.start + (sub.paymentsMade + 1) * sub.period,
            "BeaverRouter: subscription has expired"
        );

        IERC20(sub.token).transferFrom(sub.user, sub.merchant, sub.amount);
        sub.paymentsMade += 1;

        emit PaymentMade(subscriptionHash, sub.paymentsMade);
    }

    function terminateSubscription(bytes32 subscriptionHash) external {
        Subscription storage sub = subscriptions[subscriptionHash];

        require(
            msg.sender == sub.user,
            "BeaverRouter: only the user can terminate the subscription"
        );

        sub.terminated = true;
        emit SubscriptionTerminated(subscriptionHash);
    }
}
