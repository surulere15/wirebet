// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../market/WirebetMarket.sol";
import "../vault/Vault4626Minimal.sol";
import "../positions/Positions1155.sol";
import "../interfaces/IWirebetMarket.sol";

/**
 * @title MarketFactory
 * @author JOE
 * @notice Deploys and wires up new WirebetMarket + Vault pairs via CREATE2.
 * - Each market gets a dedicated Vault4626Minimal for collateral isolation.
 * - The shared Positions1155 contract is granted minter rights per market.
 * - Uses CREATE2 with marketId as salt for deterministic addresses.
 */
contract MarketFactory is Ownable {
    Positions1155 public immutable positions;
    address public immutable feeRouter;
    address public immutable collateral;

    uint256 public marketCount;

    mapping(bytes32 => address) public markets;
    mapping(bytes32 => address) public vaults;
    bytes32[] public allMarketIds;

    event MarketCreated(
        bytes32 indexed marketId,
        address indexed market,
        address indexed vault,
        address resolver,
        uint64 closeTime
    );

    error MarketExists();
    error InvalidParams();

    constructor(
        address _positions,
        address _feeRouter,
        address _collateral
    ) Ownable(msg.sender) {
        if (_positions == address(0) || _feeRouter == address(0) || _collateral == address(0)) {
            revert InvalidParams();
        }
        positions = Positions1155(_positions);
        feeRouter = _feeRouter;
        collateral = _collateral;
    }

    /**
     * @notice Deploys a new prediction market with its own vault.
     * @param _questionHash Unique identifier for the market question (e.g. keccak256 of IPFS CID).
     * @param _resolver Address authorized to resolve/cancel this market.
     * @param _closeTime Unix timestamp after which trading closes.
     * @param _risk Risk parameters (feeBps, bufferBps, maxNetExposureBps, maxTradeSizeUSDC6).
     * @param _bUSDC6 LMSR liquidity parameter in USDC6 units.
     * @return marketAddr The deployed WirebetMarket address.
     * @return vaultAddr The deployed Vault4626Minimal address.
     */
    function createMarket(
        bytes32 _questionHash,
        address _resolver,
        uint64 _closeTime,
        RiskParams calldata _risk,
        uint256 _bUSDC6
    ) external onlyOwner returns (address marketAddr, address vaultAddr) {
        if (_resolver == address(0)) revert InvalidParams();
        if (_closeTime <= block.timestamp) revert InvalidParams();
        if (_bUSDC6 == 0) revert InvalidParams();

        // Derive a unique marketId from the question hash and a monotonic nonce
        bytes32 marketId = keccak256(abi.encodePacked(_questionHash, marketCount));
        if (markets[marketId] != address(0)) revert MarketExists();

        // 1. Deploy a dedicated vault for this market
        Vault4626Minimal vault = new Vault4626Minimal{salt: marketId}(
            collateral,
            string.concat("Wirebet Vault #", _uint2str(marketCount)),
            string.concat("wV", _uint2str(marketCount))
        );
        vaultAddr = address(vault);

        // 2. Deploy the market, wiring in all dependencies
        WirebetMarket market = new WirebetMarket{salt: marketId}(
            marketId,
            collateral,
            vaultAddr,
            address(positions),
            feeRouter,
            _resolver,
            _closeTime,
            _risk,
            _bUSDC6
        );
        marketAddr = address(market);

        // 3. Wire the vault to accept calls only from this market
        vault.setMarket(marketAddr);

        // 4. Transfer vault ownership to the factory owner for admin flexibility
        vault.transferOwnership(owner());

        // 5. Authorize the market to mint/burn position tokens
        positions.setMinter(marketAddr, true);

        // 6. Record
        markets[marketId] = marketAddr;
        vaults[marketId] = vaultAddr;
        allMarketIds.push(marketId);
        marketCount++;

        emit MarketCreated(marketId, marketAddr, vaultAddr, _resolver, _closeTime);
    }

    /**
     * @notice Returns the total number of markets created.
     */
    function totalMarkets() external view returns (uint256) {
        return allMarketIds.length;
    }

    /**
     * @notice Predicts the address a market would be deployed to.
     * @dev Useful for front-end UX: show the market address before it exists.
     */
    function predictMarketAddress(bytes32 _questionHash, uint256 _nonce)
        external
        view
        returns (address)
    {
        bytes32 marketId = keccak256(abi.encodePacked(_questionHash, _nonce));
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                marketId,
                keccak256(type(WirebetMarket).creationCode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    /**
     * @notice Revokes minter rights for a market (e.g. after resolution for safety).
     */
    function revokeMinter(address market) external onlyOwner {
        positions.setMinter(market, false);
    }

    // --- Internal ---

    function _uint2str(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
