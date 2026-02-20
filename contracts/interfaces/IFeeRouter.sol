// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFeeRouter {
    function routeTradeFee(bytes32 marketId, address token, uint256 amount) external;
}
