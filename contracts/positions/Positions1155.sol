// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../market/MarketErrors.sol";

/**
 * @title Positions1155
 * @author JOE
 * @notice An ERC-1155 contract to represent YES/NO shares in prediction markets.
 * - Ownership is managed by Ownable.
 * - Minting and burning are restricted to authorized 'minter' contracts.
 * - Token IDs are deterministically derived from a marketId and the outcome side.
 */
contract Positions1155 is ERC1155, Ownable {
    mapping(address => bool) public isMinter;

    event MinterStatusChanged(address indexed minter, bool isMinter);

    modifier onlyMinter() {
        if (!isMinter[msg.sender]) revert NotMinter(msg.sender);
        _;
    }

    constructor() ERC1155("") Ownable(msg.sender) {}

    /**
     * @notice Sets or revokes minter status for a contract (e.g., a WirebetMarket).
     * @dev Only callable by the contract owner.
     * @param minter The address to grant or revoke minter status from.
     * @param allowed The boolean status to set.
     */
    function setMinter(address minter, bool allowed) public onlyOwner {
        isMinter[minter] = allowed;
        emit MinterStatusChanged(minter, allowed);
    }

    /**
     * @notice Mints position tokens (with data).
     * @dev Only callable by an authorized minter contract.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public onlyMinter {
        _mint(to, id, amount, data);
    }

    /**
     * @notice Mints position tokens (without data).
     * @dev Convenience overload for market contracts.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyMinter {
        _mint(to, id, amount, "");
    }

    /**
     * @notice Burns position tokens.
     * @dev Only callable by an authorized minter contract.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyMinter {
        _burn(from, id, amount);
    }

    /**
     * @notice Computes the deterministic token ID for a given market and side.
     * @param marketId The unique identifier for the market.
     * @param side The outcome side (0 for YES, 1 for NO).
     * @return The computed ERC-1155 token ID.
     */
    function tokenId(bytes32 marketId, uint8 side)
        public
        pure
        returns (uint256)
    {
        if (side > 1) revert InvalidSide();
        return (uint256(marketId) << 1) | side;
    }
}
