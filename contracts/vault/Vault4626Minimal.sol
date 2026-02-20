// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWirebetMarket.sol"; // For error types if needed

/**
 * @title Vault4626Minimal
 * @author JOE
 * @notice A minimal, non-yield-bearing ERC-4626 vault for holding market collateral.
 * - This implementation maintains a 1:1 ratio of shares to assets.
 * - It is owned and primarily controlled by the WirebetMarket contract.
 * - Includes a simple withdrawal fee mechanism as specified in the blueprint.
 */
contract Vault4626Minimal is ERC20, Ownable {
    IERC20 public immutable asset; // The underlying collateral token (USDC)
    address public market; // The WirebetMarket contract that controls this vault

    uint16 public withdrawFeeBps;

    event WithdrawFeeSet(uint16 newFeeBps);
    event FeesAccrued(uint256 assets);

    error Unauthorized();
    error InvalidBps();

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
        if (market != address(0)) revert(); // Already set
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
        asset.transferFrom(msg.sender, address(this), assets);
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
        asset.transfer(receiver, shares);
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
        asset.transfer(receiver, assets);
        return assets;
    }

    // =================================================================
    // Wirebet Vault Specific Functions
    // =================================================================

    function setWithdrawFeeBps(uint16 _newFeeBps) external onlyOwner {
        if (_newFeeBps > 10_000) revert InvalidBps();
        withdrawFeeBps = _newFeeBps;
        emit WithdrawFeeSet(_newFeeBps);
    }

    /**
     * @notice A function to account for accrued fees, as per the interface.
     * In this simple vault, this is a conceptual hook for future use.
     */
    function accrueFees(uint256 _assets) external onlyMarket {
        emit FeesAccrued(_assets);
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
