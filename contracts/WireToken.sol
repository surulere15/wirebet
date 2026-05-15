// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WireToken
 * @dev The official $WIRE token for the Wirebet protocol. 
 * Fixed supply of 1 billion tokens, community-owned from day zero.
 */
contract WireToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Wirebet", "WIRE") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000_000 * 10 ** decimals());
    }
}
