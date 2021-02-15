# equipment for off-chain asset backed lending in MakerDAO

## components:

- `RwaLiquidationOracle`: which acts as a liquidation beacon for an off-chain enforcer.
- `RwaUrn`: which facilitates borrowing of DAI, delivering to a designated account.
- `RwaOutputConduit` and `RwaInputConduit`: which disburse and repay DAI
- `RwaSpell`: which deploys and activates a new collateral type
- `RwaToken`: which represents the RWA collateral in the system

## todo:

- `RwaTellSpell`: which allows MakerDAO governance to initiate liquidation proceedings.
- `RwaRemedySpell`: which allows MakerDAO governance to dismiss liquidation proceedings.
- `RwaWriteoffSpell`: which allows MakerDAO governance to write off a loan which was in liquidation.

## deploy

### kovan
```
make deploy-kovan
```

### mainnet
```
make deploy-mainnet
```
