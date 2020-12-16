#!/bin/sh

ILK="RWA-001"
ILK_ENCODED=$(seth --to-bytes32 "$(seth --from-ascii ${ILK})"))

# build it
SOLC_FLAGS="--optimize --optimize-runs=1"
dapp --use solc:0.5.12 build

# tokenize it
RWA_TOKEN=$(dapp create RwaToken)

# route it
RWA_ROUTING_CONDUIT=$(dapp create RwaRoutingConduit ${MCD_GOV} ${MCD_DAI})
# TODO add hope() calls for trust
# TODO add kiss() calls for trust
seth send ${RWA_ROUTING_CONDUIT} 'rely(address)' ${MCD_PAUSE_PROXY}
seth send ${RWA_ROUTING_CONDUIT} 'deny(address)' ${ETH_FROM}

# join it
RWA_JOIN=$(dapp create AuthGemJoin ${MCD_VAT} ${ILK_ENCODED} ${RWA_TOKEN})
seth send ${RWA_ROUTING_CONDUIT} 'rely(address)' ${MCD_PAUSE_PROXY}
seth send ${RWA_ROUTING_CONDUIT} 'deny(address)' ${ETH_FROM}

# urn it
RWA_URN=$(dapp create RwaUrn ${MCD_VAT} ${RWA_JOIN} ${MCD_DAI} ${RWA_ROUTING_CONDUIT})
# TODO add hope() calls for operator
seth send ${RWA_FLIPPER} 'rely(address)' ${MCD_PAUSE_PROXY}
seth send ${RWA_FLIPPER} 'deny(address)' ${ETH_FROM}

# connect it
RWA_CONDUIT=$(dapp create RwaConduit ${MCD_GOV} ${MCD_DAI} ${RWA_URN})

# flip it
RWA_FLIPPER=$(dapp create RwaFlipper ${MCD_VAT} ${MCD_CAT} ${ILK_ENCODED})
seth send ${RWA_FLIPPER} 'rely(address)' ${MCD_PAUSE_PROXY}
seth send ${RWA_FLIPPER} 'deny(address)' ${ETH_FROM}

# price it
RWA_LIQUIDATION_ORACLE=$(dapp create RwaLiquidationOracle)
seth send ${RWA_LIQUIDATION_ORACLE} 'rely(address)' ${MCD_PAUSE_PROXY}
seth send ${RWA_LIQUIDATION_ORACLE} 'deny(address)' ${ETH_FROM}

# print it
echo "ILK: ${ILK}"
echo "${RWA}: ${RWA_TOKEN}"
echo "${RWA}_URN: ${RWA_URN}"
echo "${RWA}_JOIN: ${RWA_JOIN}"
echo "${RWA}_FLIPPER: ${RWA_FLIPPER}"
echo "${RWA}_CONDUIT: ${RWA_CONDUIT}"
echo "${RWA}_ROUTING_CONDUIT: ${RWA_ROUTING_CONDUIT}"
echo "${RWA}_LIQUIDATION_ORACLE: ${RWA_LIQUIDATION_ORACLE}"

# technologic
# https://www.youtube.com/watch?v=D8K90hX4PrE
