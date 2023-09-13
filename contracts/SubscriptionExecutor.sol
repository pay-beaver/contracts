// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubscriptionExecutor {
    event SubscriptionPayment(
        address indexed from,
        address indexed to,
        string indexed subscriptionId,
        uint256 value
    );

    function payForSubscription(
        address _token,
        uint256 _amount,
        address _to,
        string calldata subscriptionId
    ) external {
        IERC20(_token).transfer(_to, _amount);
        emit SubscriptionPayment(msg.sender, _to, subscriptionId, _amount);
    }
}
