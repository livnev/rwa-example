pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/EndAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";
import "lib/dss-interfaces/src/dapp/DSValueAbstract.sol";

interface RwaLiquidationLike {
    function wards(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function init(bytes32, bytes32, address, uint48) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32) external;
    function good(bytes32) external view;
}

interface RwaConduitLike {
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

contract SpellAction {
    // KOVAN ADDRESSES
   //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address constant MCD_VAT      = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant MCD_CAT      = 0xdDb5F7A3A5558b9a6a1f3382BD75E2268d1c6958;
    address constant MCD_JUG      = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant MCD_SPOT     = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant MCD_END      = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    address constant ILK_REGISTRY = 0xedE45A0522CA19e979e217064629778d6Cc2d9Ea;

    /*
        OPERATOR: 0xD23beB204328D7337e3d2Fb9F150501fDC633B0e
        TRUST1: 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711
        TRUST2: 0xDA0111100cb6080b43926253AB88bE719C60Be13
        ILK: RWA001-A
        RWA001: 0x2373bEFCDB6B8Ea808Ac2CD2Cf15a99fF3dc8132
        PIP_RWA001: 0x7f6666bFB825cF10423b91Ac5f119D63a5A00C47
        MCD_JOIN_RWA001_A: 0xd22da469EdbdAe73ECdFe0EB460BaE048d08E1B0
        MCD_FLIP_RWA001_A: 0x539714891180e37d7144F4d845402F7Fb89098CD
        RWA001_A_URN: 0x708cE58F013843816e7eaaa4Ab8E4341D29D8Cc8
        RWA001_A_CONDUIT: 0xa2A1362E6283e8020DC6FC0F46C51e0da8eF345F
        RWA001_A_ROUTING_CONDUIT: 0xa6061a6e85c387Cc757c194961BCc3DB90f9e831
        RWA001_LIQUIDATION_ORACLE: 0x0380A1d2876648894C4892480A3c4312c4904887
    */
    address constant RWA001_GEM                = 0x2373bEFCDB6B8Ea808Ac2CD2Cf15a99fF3dc8132;
    address constant PIP_RWA001                = 0x7f6666bFB825cF10423b91Ac5f119D63a5A00C47;
    address constant MCD_JOIN_RWA001_A         = 0xd22da469EdbdAe73ECdFe0EB460BaE048d08E1B0;
    address constant MCD_FLIP_RWA001_A         = 0x539714891180e37d7144F4d845402F7Fb89098CD;
    address constant RWA001_A_URN              = 0x708cE58F013843816e7eaaa4Ab8E4341D29D8Cc8;
    address constant RWA001_A_CONDUIT          = 0xa2A1362E6283e8020DC6FC0F46C51e0da8eF345F;
    address constant RWA001_A_ROUTING_CONDUIT  = 0xa6061a6e85c387Cc757c194961BCc3DB90f9e831;
    address constant RWA001_LIQUIDATION_ORACLE = 0x0380A1d2876648894C4892480A3c4312c4904887;

    // may be able to assign these as immutable
    // try constants
    DSValueAbstract constant pippip = DSValueAbstract(PIP_RWA001);

    RwaLiquidationLike constant oracle =
        RwaLiquidationLike(RWA001_LIQUIDATION_ORACLE);

    uint256 constant SIX_PCT_RATE    = 1000000001847694957439350562;

    // precision
    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    function execute() external {
        // RWA001-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA001-A";

        // add RWA-001 contract to the changelog
        CHANGELOG.setAddress("RWA001", RWA001_GEM);
        CHANGELOG.setAddress("PIP_RWA001", PIP_RWA001);
        CHANGELOG.setAddress("MCD_JOIN_RWA001_A", MCD_JOIN_RWA001_A);
        CHANGELOG.setAddress("MCD_FLIP_RWA001_A", MCD_FLIP_RWA001_A);
        CHANGELOG.setAddress("RWA001_LIQUIDATION_ORACLE", RWA001_LIQUIDATION_ORACLE);
        CHANGELOG.setAddress("RWA001_A_URN", RWA001_A_URN);
        CHANGELOG.setAddress("RWA001_A_CONDUIT", RWA001_A_CONDUIT);
        CHANGELOG.setAddress("RWA001_A_ROUTING_CONDUIT", RWA001_A_ROUTING_CONDUIT);

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).gem() == RWA001_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).dec() == DSTokenAbstract(RWA001_GEM).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_RWA001_A).vat()    == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_RWA001_A).ilk()    == ilk, "flip-ilk-not-match");

        // Set price feed for RWA001
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_RWA001);

        // Set the RWA-001 flipper in the cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_RWA001_A);

        // Init RWA-001 in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init RWA-001 in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow RWA-001 Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_RWA001_A);

        // Allow RWA-001 Flipper on the Cat
        CatAbstract(MCD_CAT).rely(MCD_FLIP_RWA001_A);

        // Allow cat to kick auctions in RWA-001 Flipper
        FlipAbstract(MCD_FLIP_RWA001_A).rely(MCD_CAT);

        // Allow End to yank auctions in RWA-001 Flipper
        // FlipAbstract(MCD_FLIP_RWA001_A).rely(MCD_END);

        // 1000 debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 1000 * RAD);

        // No dust
        // VatAbstract(MCD_VAT).file(ilk, "dust", 0)

        // 100M dunk
        CatAbstract(MCD_CAT).file(ilk, "dunk", 100 * MILLION * RAD);

        // 0% liq. penalty
        CatAbstract(MCD_CAT).file(ilk, "chop", WAD);

        // 6% stability fee TODO ask matt
        JugAbstract(MCD_JUG).file(ilk, "duty", SIX_PCT_RATE);

        // NOTE: nothing to file on the flipper
        // FlipAbstract(MCD_FLIP_RWA001_A).file("beg" , 103 * WAD / 100);
        // FlipAbstract(MCD_FLIP_RWA001_A).file("ttl" , 6 hours);
        // FlipAbstract(MCD_FLIP_RWA001_A).file("tau" , 6 hours);

        // collateralization ratio 100%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", RAY);

        // poke the spotter to pull in a price
        SpotAbstract(MCD_SPOT).poke(ilk);

        // DOC hash (TODO)
        bytes32 doc = "doc";

        // init the RwaLiquidationOracle
        // doc: "doc" TODO
        // tau: 5 minutes
        oracle.init(ilk, doc, PIP_RWA001, 300);

        // ilk registry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_RWA001_A);
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
        expiration = now + 30 days;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
