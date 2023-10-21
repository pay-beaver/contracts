// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Subscription {
    address user;
    address merchant;
    string metadata;
    address token;
    uint256 amount;
    uint256 period;
    uint256 start;
    uint256 paymentPeriod; // How many seconds there is to make a payment
    uint256 paymentsMade; // 1 - one payment has been made, 2 - two payments have been made, etc.
    bool terminated;
    address initiator; // who is allowed to initiate payments
}

contract BeaverRouter {
    address _owner;
    uint256 _fee;

    constructor(address owner) {
        _owner = owner;
        _fee = (5 * (10 ** 18)) / 1000; // Initially setting to 0.5%
    }

    event SubscriptionStarted(
        bytes32 indexed subscriptionHash,
        address indexed user,
        address indexed merchant,
        string metadata,
        address token,
        uint256 amount,
        uint256 period,
        uint256 start,
        uint256 paymentPeriod,
        address initiator
    );

    event PaymentMade(
        bytes32 indexed subscriptionHash,
        uint256 indexed paymentNumber
    );

    event SubscriptionTerminated(bytes32 indexed subscriptionHash);

    mapping(bytes32 => Subscription) public subscriptions;
    mapping(address => mapping(address => uint256)) txCompensations; // Compensation for gas fees spent by initiator. token address => merchant address => amount.
    mapping(address => uint256) earnedFees; // token address => amount
    mapping(address => uint256) merchantNonce;

    function startSubscription(
        address merchant,
        string calldata metadata, // subscriptionId, merchantDomain, product name and other data that is not needed to make payments.
        address token,
        uint256 amount,
        uint256 period,
        uint256 freeTrialLength,
        uint256 paymentPeriod,
        address initiator
    ) external returns (bytes32 subscriptionHash) {
        // Subscription hash is a unique identifier for every subscription.
        subscriptionHash = keccak256(
            abi.encodePacked(block.chainid, merchant, merchantNonce[merchant]++)
        );

        uint256 start = block.timestamp + freeTrialLength;
        subscriptions[subscriptionHash] = Subscription(
            msg.sender,
            merchant,
            metadata,
            token,
            amount,
            period,
            start,
            paymentPeriod,
            0,
            false,
            initiator
        );

        emit SubscriptionStarted(
            subscriptionHash,
            msg.sender,
            merchant,
            metadata,
            token,
            amount,
            period,
            start,
            paymentPeriod,
            initiator
        );

        if (freeTrialLength == 0) this.makePayment(subscriptionHash, 0);
    }

    function makePayment(
        bytes32 subscriptionHash,
        uint256 compensation
    ) external returns (bool) {
        Subscription storage sub = subscriptions[subscriptionHash];

        require(
            msg.sender == address(this) || msg.sender == sub.initiator,
            "BeaverRouter: only initiator is allowed to initiate payments"
        );

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

        uint256 fee = (sub.amount * _fee) / (10 ** 18);
        uint256 toRouter = compensation + fee;

        require(
            toRouter < sub.amount, // prevent initiators from making the compensation too high
            "BeaverRouter: too much to send to the router"
        );

        uint256 toMerchant = sub.amount - toRouter;

        IERC20(sub.token).transferFrom(sub.user, sub.merchant, toMerchant);
        IERC20(sub.token).transferFrom(sub.user, address(this), toRouter);

        txCompensations[sub.token][sub.initiator] += compensation;
        earnedFees[sub.token] += fee;

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
