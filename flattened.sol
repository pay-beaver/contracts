// Sources flattened with hardhat v2.18.2 https://hardhat.org

// SPDX-License-Identifier: MIT AND UNLICENSED

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File contracts/BeaverRouter.sol

// Original license: SPDX_License_Identifier: UNLICENSED

pragma solidity ^0.8.19;

contract BeaverRouter {
    address public owner;
    bool public frozen;
    address public defaultInitiator;

    constructor(address constructorOwner, address constructorDefaultInitiator) {
        owner = constructorOwner;
        defaultInitiator = constructorDefaultInitiator;
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

    event Freezed();

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
    ) external returns (bool) {
        require(_owner != address(0), "BR: router is frozen");

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
        return true;
    }

    function terminateSubscription(
        bytes32 subscriptionHash
    ) external returns (bool) {
        Subscription storage sub = subscriptions[subscriptionHash];
        Product storage product = products[sub.productHash];

        sub.terminated = true;
        emit SubscriptionTerminated(subscriptionHash, msg.sender);
        return true;
    }

    function changeInitiator(
        address merchant,
        address newInitiator
    ) external returns (bool) {
        address initiator = merchantSettings[merchant].initiator;

        require(
            msg.sender == initiator ||
                msg.sender == merchant ||
                (initiator == address(0) && newInitiator == _defaultInitiator),
            "BR: not permitted"
        );

        emit InitiatorChanged(merchant, newInitiator, initiator, msg.sender);
        merchantSettings[merchant].initiator = newInitiator;
        return true;
    }

    function changeOwner(address newOwner) external returns (bool) {
        require(msg.sender == _owner, "BR: not permitted");

        emit OwnerChanged(newOwner, _owner);

        _owner = newOwner;
        return true;
    }

    function freeze() external returns (bool) {
        require(msg.sender == _owner, "BR: not permitted");

        emit Froze();
    }

    function changeDefaultInitiator(
        address newDefaultInitiator
    ) external returns (bool) {
        emit DefaultInitiatorChanged(newDefaultInitiator, _defaultInitiator);

        _defaultInitiator = newDefaultInitiator;
        return true;
    }
}
