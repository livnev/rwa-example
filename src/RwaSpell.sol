pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSValueAbstract.sol";

interface RwaLiquidationLike {
    function wards(address) external returns (uint256);
    function ilks(bytes32) external returns (bytes32,address,uint48,uint48);
    function rely(address) external;
    function deny(address) external;
    function init(bytes32, uint256, string calldata, uint48) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32) external;
    function good(bytes32) external view;
}

interface RwaOutputConduitLike {
    function wards(address) external returns (uint256);
    function can(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function hope(address) external;
    function nope(address) external;
    function bud(address) external returns (uint256);
    function kiss(address) external;
    function diss(address) external;
    function pick(address) external;
    function push() external;
}

interface RwaUrnLike {
    function hope(address) external;
}

contract SpellAction {
    // KOVAN ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // core address helpers
    function vat()  internal view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function jug()  internal view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function spot() internal view returns (address) { return getChangelogAddress("MCD_SPOT"); }

    function getChangelogAddress(bytes32 key) internal view returns (address) {
        return ChainlogAbstract(CHANGELOG).getAddress(key);
    }

    /*
        OPERATOR: 0xD23beB204328D7337e3d2Fb9F150501fDC633B0e
        TRUST1: 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711
        TRUST2: 0xDA0111100cb6080b43926253AB88bE719C60Be13
        ILK: RWA001-A
        RWA001: 0x402BEfAF2deea5f772A8aE901cFD8a26f8F36c2F
        MCD_JOIN_RWA001_A: 0x2225c0034dBD4250ac431F899dEBf039A0384AEC
        RWA001_A_URN: 0x1eF19d05DE248Eb7BdEF5c4C41C765745697dbaf
        RWA001_A_CONDUIT_IN: 0x4ba5eF5A3eE15cbd3552B04DC7dBF0bc77CA886b
        RWA001_A_CONDUIT_OUT: 0x5823D8cDA9a9B8ea16Bd7D97ed63B702AC4b30FD
        MIP21_LIQUIDATION_ORACLE: 0x856f61A4DbD981f477ea60203251bB748aa36e89
    */
    address constant RWA001_OPERATOR           = 0xD23beB204328D7337e3d2Fb9F150501fDC633B0e;
    address constant RWA001_GEM                = 0x402BEfAF2deea5f772A8aE901cFD8a26f8F36c2F;
    address constant MCD_JOIN_RWA001_A         = 0x2225c0034dBD4250ac431F899dEBf039A0384AEC;
    address constant RWA001_A_URN              = 0x1eF19d05DE248Eb7BdEF5c4C41C765745697dbaf;
    address constant RWA001_A_INPUT_CONDUIT    = 0x4ba5eF5A3eE15cbd3552B04DC7dBF0bc77CA886b;
    address constant RWA001_A_OUTPUT_CONDUIT   = 0x5823D8cDA9a9B8ea16Bd7D97ed63B702AC4b30FD;
    address constant MIP21_LIQUIDATION_ORACLE  = 0x856f61A4DbD981f477ea60203251bB748aa36e89;

    uint256 constant SIX_PCT_RATE    = 1000000001847694957439350562;

    // precision
    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    uint256 constant RWA001_A_INITIAL_DC    = 1000 * RAD;
    uint256 constant RWA001_A_INITIAL_PRICE = 1060 * WAD;

    // MIP13c3-SP4 Declaration of Intent & Commercial Points -
    //   Off-Chain Asset Backed Lender to onboard Real World Assets
    //   as Collateral for a DAI loan
    //
    // https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk
    string constant DOC = "QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk";

    function execute() external {
        // RWA001-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA001-A";

        // add RWA-001 contract to the changelog
        CHANGELOG.setAddress("RWA001", RWA001_GEM);
        CHANGELOG.setAddress("MCD_JOIN_RWA001_A", MCD_JOIN_RWA001_A);
        CHANGELOG.setAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        CHANGELOG.setAddress("RWA001_A_URN", RWA001_A_URN);
        CHANGELOG.setAddress("RWA001_A_INPUT_CONDUIT", RWA001_A_INPUT_CONDUIT);
        CHANGELOG.setAddress("RWA001_A_OUTPUT_CONDUIT", RWA001_A_OUTPUT_CONDUIT);

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).vat() == vat(), "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).gem() == RWA001_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).dec() == DSTokenAbstract(RWA001_GEM).decimals(), "join-dec-not-match");

        // init the RwaLiquidationOracle
        // doc: "doc"
        // tau: 5 minutes
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, RWA001_A_INITIAL_PRICE, DOC, 300
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        CHANGELOG.setAddress("PIP_RWA001", pip);

        // Set price feed for RWA001
        SpotAbstract(spot()).file(ilk, "pip", pip);

        // Init RWA-001 in Vat
        VatAbstract(vat()).init(ilk);
        // Init RWA-001 in Jug
        JugAbstract(jug()).init(ilk);

        // Allow RWA-001 Join to modify Vat registry
        VatAbstract(vat()).rely(MCD_JOIN_RWA001_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        VatAbstract(vat()).rely(MIP21_LIQUIDATION_ORACLE);

        // 1000 debt ceiling
        VatAbstract(vat()).file(ilk, "line", RWA001_A_INITIAL_DC);
        VatAbstract(vat()).file("Line", VatAbstract(vat()).Line() + RWA001_A_INITIAL_DC);

        // No dust
        // VatAbstract(vat()).file(ilk, "dust", 0)

        // 6% stability fee TODO ask matt
        JugAbstract(jug()).file(ilk, "duty", SIX_PCT_RATE);

        // collateralization ratio 100%
        SpotAbstract(spot()).file(ilk, "mat", RAY);

        // poke the spotter to pull in a price
        SpotAbstract(spot()).poke(ilk);

        // TODO: add to deploy scripts and remove
        // give the urn permissions on the join adapter
        GemJoinAbstract(MCD_JOIN_RWA001_A).rely(RWA001_A_URN);

        // set up the urn
        RwaUrnLike(RWA001_A_URN).hope(RWA001_OPERATOR);

        // set up output conduit
        RwaOutputConduitLike(RWA001_A_OUTPUT_CONDUIT).hope(RWA001_OPERATOR);
        // could potentially kiss some BD addresses if they are available
    }
}

contract RwaSpell {

    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    string constant public description = "Kovan Spell Deploy";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = block.timestamp + 30 days;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
