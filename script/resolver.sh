#!/usr/bin/env bash
# Wirebet Resolver CLI — manage market lifecycle via cast
#
# Usage:
#   ./resolver.sh status  <market_address>
#   ./resolver.sh lock    <market_address>
#   ./resolver.sh resolve <market_address> YES|NO
#   ./resolver.sh cancel  <market_address>
#   ./resolver.sh sweep   <market_address>
#
# Environment:
#   PRIVATE_KEY           — resolver's private key
#   BASE_SEPOLIA_RPC_URL  — RPC endpoint (default: https://sepolia.base.org)

set -euo pipefail

RPC="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
CMD="${1:-help}"
MARKET="${2:-}"

state_label() {
    case "$1" in
        0) echo "OPEN" ;;
        1) echo "LOCKED" ;;
        2) echo "RESOLVED" ;;
        3) echo "CANCELLED" ;;
        *) echo "UNKNOWN($1)" ;;
    esac
}

result_label() {
    case "$1" in
        0) echo "UNSET" ;;
        1) echo "YES" ;;
        2) echo "NO" ;;
        3) echo "CANCELLED" ;;
        *) echo "UNKNOWN($1)" ;;
    esac
}

case "$CMD" in
    status)
        [ -z "$MARKET" ] && echo "Usage: $0 status <market_address>" && exit 1
        echo "--- Market Status ---"
        echo "Address:   $MARKET"

        STATE=$(cast call "$MARKET" "state()(uint8)" --rpc-url "$RPC")
        echo "State:     $(state_label "$STATE")"

        RESULT=$(cast call "$MARKET" "result()(uint8)" --rpc-url "$RPC")
        echo "Result:    $(result_label "$RESULT")"

        PRICE=$(cast call "$MARKET" "priceYes1e18()(uint256)" --rpc-url "$RPC")
        PCT=$(echo "scale=2; $PRICE / 10000000000000000" | bc)
        echo "YES Price: ${PCT}%"

        CLOSE=$(cast call "$MARKET" "closeTime()(uint64)" --rpc-url "$RPC")
        echo "CloseTime: $CLOSE ($(date -r "$CLOSE" 2>/dev/null || echo 'use: date -d @'"$CLOSE"))"

        QY=$(cast call "$MARKET" "qY()(uint256)" --rpc-url "$RPC")
        QN=$(cast call "$MARKET" "qN()(uint256)" --rpc-url "$RPC")
        echo "qY:        $QY"
        echo "qN:        $QN"

        FEES=$(cast call "$MARKET" "feesAccruedUSDC6()(uint256)" --rpc-url "$RPC")
        echo "Fees:      $FEES"
        ;;

    lock)
        [ -z "$MARKET" ] && echo "Usage: $0 lock <market_address>" && exit 1
        echo "Locking market $MARKET..."
        cast send "$MARKET" "lock()" \
            --rpc-url "$RPC" --private-key "$PRIVATE_KEY"
        echo "Market locked."
        ;;

    resolve)
        [ -z "$MARKET" ] && echo "Usage: $0 resolve <market_address> YES|NO" && exit 1
        OUTCOME="${3:-}"
        case "$OUTCOME" in
            YES) RESULT_UINT=1 ;;
            NO)  RESULT_UINT=2 ;;
            *)   echo "Usage: $0 resolve <market_address> YES|NO" && exit 1 ;;
        esac
        EVIDENCE=$(cast keccak "resolved:$OUTCOME:$(date +%s)")
        echo "Resolving market $MARKET as $OUTCOME..."
        cast send "$MARKET" "resolve(uint8,bytes32)" "$RESULT_UINT" "$EVIDENCE" \
            --rpc-url "$RPC" --private-key "$PRIVATE_KEY"
        echo "Market resolved as $OUTCOME."
        ;;

    cancel)
        [ -z "$MARKET" ] && echo "Usage: $0 cancel <market_address>" && exit 1
        REASON=$(cast keccak "cancelled:$(date +%s)")
        echo "Cancelling market $MARKET..."
        cast send "$MARKET" "cancel(bytes32)" "$REASON" \
            --rpc-url "$RPC" --private-key "$PRIVATE_KEY"
        echo "Market cancelled."
        ;;

    sweep)
        [ -z "$MARKET" ] && echo "Usage: $0 sweep <market_address>" && exit 1
        echo "Sweeping fees from $MARKET..."
        cast send "$MARKET" "sweepFees()" \
            --rpc-url "$RPC" --private-key "$PRIVATE_KEY"
        echo "Fees swept."
        ;;

    help|*)
        echo "Wirebet Resolver CLI"
        echo ""
        echo "Usage:"
        echo "  $0 status  <market>          Show market state, price, close time"
        echo "  $0 lock    <market>          Lock market (after close time)"
        echo "  $0 resolve <market> YES|NO   Resolve market outcome"
        echo "  $0 cancel  <market>          Cancel market"
        echo "  $0 sweep   <market>          Sweep accrued fees to treasury"
        echo ""
        echo "Environment:"
        echo "  PRIVATE_KEY           Resolver's private key"
        echo "  BASE_SEPOLIA_RPC_URL  RPC endpoint (default: https://sepolia.base.org)"
        ;;
esac
