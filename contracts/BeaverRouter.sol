// // SPDX-License-Identifier: UNLICENSED

// pragma solidity ^0.8.19;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract BeaverRouter {
//     address _owner;
//     address _defaultInitiator;

//     constructor(address owner, address defaultInitiator) {
//         _owner = owner;
//         _defaultInitiator = defaultInitiator;
//     }

//     // period - how often payments are made
//     // payment period - time to make a single payment
//     struct Product {
//         bytes26 merchantAndPeriod; // merchant (20 bytes) + period (6 bytes)
//         bytes32 tokenAndFreeTrialAndPaymentPeriod; // token address (20 bytes), free trial length (6 bytes), payment period (6 bytes)
//         uint256 amount;
//         bytes32 productMetadata; // product metadata like product name
//     }

//     struct Subscription {
//         bytes32 productHash;
//         bytes32 crucialData; // user (20 bytes), start timestamp (6 bytes), paymentsMade (5 bytes), terminated (1 byte)
//         bytes32 subscriptionMetadata; // subscription metadata like subscriptionId, userId
//     }

//     struct MerchantSettings {
//         address initiator;
//     }

//     event ProductCreated(
//         bytes32 indexed productHash,
//         address indexed merchant,
//         address indexed token,
//         uint256 amount,
//         uint256 period,
//         uint256 freeTrialLength,
//         uint256 paymentPeriod,
//         bytes32 productMetadata
//     );

//     event SubscriptionStarted(
//         bytes32 indexed subscriptionHash,
//         bytes32 indexed productHash,
//         address indexed user,
//         uint256 start,
//         bytes32 subscriptionMetadata
//     );

//     event PaymentMade(
//         bytes32 indexed subscriptionHash,
//         uint256 indexed paymentNumber
//     );

//     event SubscriptionTerminated(
//         bytes32 indexed subscriptionHash,
//         address indexed terminatedBy
//     );

//     event InitiatorChanged(
//         address indexed merchant,
//         address indexed newInitiator,
//         address indexed oldInitiator,
//         address changedBy
//     );

//     mapping(bytes32 => Product) public products;
//     mapping(bytes32 => Subscription) public subscriptions;
//     mapping(bytes32 => uint64) public productNonce; // uint64 is the same as Ethereum's nonce for transactions
//     mapping(address => MerchantSettings) public merchantSettings;

//     function createProductIfDoesntExist(
//         address merchant,
//         bytes32 productMetadata,
//         address token,
//         uint256 amount,
//         uint256 period,
//         uint256 freeTrialLength,
//         uint256 paymentPeriod
//     ) external returns (bytes32 productHash) {
//         productHash = keccak256(
//             abi.encodePacked(
//                 block.chainid,
//                 merchant,
//                 token,
//                 amount,
//                 period,
//                 freeTrialLength,
//                 paymentPeriod,
//                 productMetadata
//             )
//         );

//         if (products[productHash].merchant != address(0)) {
//             return productHash; // product already exists
//         }

//         products[productHash] = Product(
//             merchant,
//             token,
//             amount,
//             period,
//             freeTrialLength,
//             paymentPeriod,
//             productMetadata
//         );

//         emit ProductCreated(
//             productHash,
//             merchant,
//             token,
//             amount,
//             period,
//             freeTrialLength,
//             paymentPeriod,
//             productMetadata
//         );
//     }

//     function _startSubscription(
//         bytes32 productHash,
//         bytes32 subscriptionMetadata
//     ) internal returns (bytes32 subscriptionHash) {
//         Product storage product = products[productHash];

//         require(
//             product.merchant != address(0),
//             "BeaverRouter: this product doesn't exist"
//         );

//         // not hashing chainId since it is already included in productHash.
//         subscriptionHash = keccak256(
//             abi.encodePacked(productHash, productNonce[productHash]++)
//         );

//         uint256 start = block.timestamp + product.freeTrialLength;
//         subscriptions[subscriptionHash] = Subscription(
//             productHash,
//             msg.sender,
//             start,
//             0,
//             false,
//             subscriptionMetadata
//         );

//         emit SubscriptionStarted(
//             subscriptionHash,
//             productHash,
//             msg.sender,
//             start,
//             subscriptionMetadata
//         );

//         if (product.freeTrialLength == 0) this.makePayment(subscriptionHash, 0);
//     }

//     function startSubscription(
//         bytes32 productHash,
//         bytes32 subscriptionMetadata
//     ) external returns (bytes32 subscriptionHash) {
//         subscriptionHash = _startSubscription(
//             productHash,
//             subscriptionMetadata
//         );
//     }

//     function setupEnvironmentAndStartSubscription(
//         address merchant,
//         bytes32 productMetadata,
//         address token,
//         uint256 amount,
//         uint256 period,
//         uint256 freeTrialLength,
//         uint256 paymentPeriod,
//         bytes32 subscriptionMetadata
//     ) external returns (bytes32 subscriptionHash) {
//         if (merchantSettings[merchant].initiator == address(0)) {
//             this.changeInitiator(merchant, _defaultInitiator);
//         }

//         bytes32 productHash = this.createProductIfDoesntExist(
//             merchant,
//             productMetadata,
//             token,
//             amount,
//             period,
//             freeTrialLength,
//             paymentPeriod
//         );

//         subscriptionHash = _startSubscription(
//             productHash,
//             subscriptionMetadata
//         );
//     }

//     function makePayment(
//         bytes32 subscriptionHash,
//         uint256 compensation
//     ) external returns (bool) {
//         Subscription storage sub = subscriptions[subscriptionHash];
//         Product storage product = products[sub.productHash];
//         address initiator = merchantSettings[product.merchant].initiator;

//         require(
//             msg.sender == address(this) || msg.sender == initiator,
//             "BeaverRouter: only initiator is allowed to initiate payments"
//         );

//         require(
//             !sub.terminated,
//             "BeaverRouter: subscription has been terminated"
//         );

//         uint256 paymentTimestamp = sub.start +
//             sub.paymentsMade *
//             product.period;

//         require(
//             block.timestamp >= paymentTimestamp,
//             "BeaverRouter: too early to make payment"
//         );

//         require(
//             block.timestamp < paymentTimestamp + product.paymentPeriod,
//             "BeaverRouter: subscription has expired"
//         );

//         require(
//             compensation < product.amount, // prevent initiators from making the compensation too high
//             "BeaverRouter: too high compensation"
//         );

//         uint256 toMerchant = product.amount - compensation;

//         IERC20(product.token).transferFrom(
//             sub.user,
//             product.merchant,
//             toMerchant
//         );
//         IERC20(product.token).transferFrom(sub.user, initiator, compensation);

//         sub.paymentsMade += 1;
//         emit PaymentMade(subscriptionHash, sub.paymentsMade);
//         return true;
//     }

//     function terminateSubscription(
//         bytes32 subscriptionHash
//     ) external returns (bool) {
//         Subscription storage sub = subscriptions[subscriptionHash];
//         Product storage product = products[sub.productHash];

//         require(
//             msg.sender == sub.user || msg.sender == product.merchant,
//             "BeaverRouter: only the user and the merchant can terminate the subscription"
//         );

//         sub.terminated = true;
//         emit SubscriptionTerminated(subscriptionHash, msg.sender);
//         return true;
//     }

//     function changeInitiator(
//         address merchant,
//         address newInitiator
//     ) external returns (bool) {
//         address initiator = merchantSettings[merchant].initiator;

//         require(
//             msg.sender == initiator ||
//                 msg.sender == merchant ||
//                 (initiator == address(0) && newInitiator == _defaultInitiator),
//             "BeaverRouter: only current initiator and merchant are allowed to change initiator."
//         );

//         emit InitiatorChanged(merchant, newInitiator, initiator, msg.sender);
//         merchantSettings[merchant].initiator = newInitiator;
//         return true;
//     }

//     function changeOwner(address newOwner) external returns (bool) {
//         require(
//             msg.sender == _owner,
//             "BeaverRouter: only owner can change the owner"
//         );

//         _owner = newOwner;

//         return true;
//     }

//     function changeDefaultInitiator(
//         address newDefaultInitiator
//     ) external returns (bool) {
//         require(
//             msg.sender == _owner,
//             "BeaverRouter: only owner can change the default initiator"
//         );

//         _defaultInitiator = newDefaultInitiator;

//         return true;
//     }
// }
