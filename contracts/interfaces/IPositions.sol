// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPositions {
    function tokenId(bytes32 marketId, uint8 side) external pure returns (uint256);
    function mint(address to, uint256 tokenId, uint256 amount) external;
    function burn(address from, uint256 tokenId, uint256 amount) external;
}
