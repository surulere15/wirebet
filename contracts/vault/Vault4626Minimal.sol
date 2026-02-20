// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWirebetMarket.sol"; // For error types if needed

/**
 * @title Vault4626Minimal
 * @author JOE
 * @notice A minimal, non-yield-bearing ERC-4626 vault for holding market collateral.
 * - This implementation maintains a 1:1 ratio of shares to assets.
 * - It is owned and primarily controlled by the WirebetMarket contract.
 */
contract Vault4626Minimal is ERC20, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset; // The underlying collateral token (USDC)
    address public market; // The WirebetMarket contract that controls this vault

    error Unauthorized();
    error MarketAlreadySet();

    modifier onlyMarket() {
        if (msg.sender != market) revert Unauthorized();
        _;
    }

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        asset = IERC20(_asset);
    }

    /**
     * @notice Sets the market contract address. Can only be called once by the owner.
     */
    function setMarket(address _market) external onlyOwner {
        if (market != address(0)) revert MarketAlreadySet();
        market = _market;
    }

    // =================================================================
    // ERC-4626 Core Functions (1:1 share to asset ratio)
    // =================================================================

    function totalAssets() public view virtual returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function deposit(uint256 assets, address receiver)
        public
        virtual
        onlyMarket
        returns (uint256 shares)
    {
        asset.safeTransferFrom(msg.sender, address(this), assets);
        shares = assets; // 1:1 ratio
        _mint(receiver, shares);
        return shares;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual onlyMarket returns (uint256 shares) {
        // Owner must have approved this contract to burn their shares
        _burn(owner, assets); // In 1:1, shares burned = assets withdrawn
        shares = assets;
        asset.safeTransfer(receiver, shares);
        return shares;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual onlyMarket returns (uint256 assets) {
        // Owner must have approved this contract to burn their shares
        _burn(owner, shares);
        assets = shares; // 1:1 ratio
        asset.safeTransfer(receiver, assets);
        return assets;
    }

    // Overriding decimals to match the underlying asset (e.g., 6 for USDC)
    function decimals() public view virtual override returns (uint8) {
        try IERC20Metadata(address(asset)).decimals() returns (uint8 d) {
            return d;
        } catch {
            return 18; // Default fallback
        }
    }
}
