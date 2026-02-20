// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Error when a zero address is provided where a valid address is required.
error ZeroAddress();
/// @notice Error for actions attempted by an unauthorized address.
error Unauthorized();
/// @notice Error when a function is called while the market is not in the OPEN state.
error NotOpen();
/// @notice Error when a function requires the market to be LOCKED, but it is not.
error NotLocked();
/// @notice Error when a function requires the market to be RESOLVED, but it is not.
error NotResolved();
/// @notice Error when attempting an action on a market that is not cancellable.
error NotCancellable();
/// @notice Error for attempting to resolve a market that is already resolved.
error AlreadyResolved();
/// @notice Error for attempting to close a market that is already closed/locked.
error AlreadyClosed();
/// @notice Error for attempting to cancel a market that is already cancelled.
error AlreadyCancelled();
/// @notice Error for providing an invalid outcome or side (e.g., not YES or NO).
error InvalidSide();
/// @notice Error for providing a zero or otherwise invalid amount for a transaction.
error ZeroAmount();
/// @notice Error when a trade would result in a price outside the user's slippage tolerance.
error Slippage();
/// @notice Error for attempting to close a market before its designated close time.
error TooEarly();
/// @notice Error for a trade size that exceeds the per-transaction limit.
error TooLarge();
/// @notice Error when a trade would push the market's liability beyond its exposure cap.
error ExposureExceeded();
/// @notice Error when an address that is not an authorized minter attempts to mint/burn.
error NotMinter(address sender);
