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

// NOTES:
// renamed to RWA-001
// flipmom / osm?
// SF fees? just input dummy data for right now?

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
    //     https://changelog.makerdao.com/releases/mainnet/1.1.4/contracts.json

    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address constant MCD_VAT         = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant MCD_CAT         = 0xdDb5F7A3A5558b9a6a1f3382BD75E2268d1c6958;
    address constant MCD_JUG         = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant MCD_SPOT        = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant MCD_END         = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    address constant ILK_REGISTRY    = 0xedE45A0522CA19e979e217064629778d6Cc2d9Ea;

    address constant RWA001_GEM      = 0xF1c74E2970E86cEC267b1714b2919f8A105Fb526;
    address constant MCD_JOIN_RWA001 = 0x0963237D0CBa02D9ee64f2a2f777f2eAeB7C3819;
    address constant MCD_FLIP_RWA001 = 0x8022Fd8a28A3acCE3C45bBbca8d3B7B972700153;
    address constant PIP_RWA001      = 0x51486fbD0e669b48eA28Dee273Fac5F89402f982;
    address constant RWA_URN         = 0x15A66b462daC73051e4475A24EeAcF56117BfDB1;
    address constant RWA_CONDUIT     = 0x2E465712F32ad33B4e2E78A4Aa658AB681e99338;

    // this is set to 10million right now
    address constant PIP             = 0x0318D82C3b2a23d993dcE881aada122f311ca901;

    // may be able to assign these as immutable
    // try constants
    DSValueAbstract constant pippip = DSValueAbstract(PIP);

    RwaLiquidationLike constant oracle        = RwaLiquidationLike(PIP_RWA001);

    uint256 constant SIX_PCT_RATE    = 1000000001847694957439350562;

    // precision
    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;
    
    function execute() external {

        ////////////////////////////////////////////////////////////////////////////////
        // RWA-001 collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilk = "RWA-001";

        // add RWA-001 contract to the changelog
        CHANGELOG.setAddress("RWA-001", RWA001_GEM);
        CHANGELOG.setAddress("MCD_JOIN_RWA001", MCD_JOIN_RWA001);
        CHANGELOG.setAddress("MCD_FLIP_RWA001", MCD_FLIP_RWA001);
        CHANGELOG.setAddress("PIP_RWA001", PIP_RWA001);
 
        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA001).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001).gem() == RWA001_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001).dec() == DSTokenAbstract(RWA001_GEM).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_RWA001).vat()    == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_RWA001).ilk()    == ilk, "flip-ilk-not-match");

        // Set price feed for RWA001
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_RWA001);

        // // // Set the RWA-001 flipper in the cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_RWA001);

        // // // Init RWA-001 in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // // // Init RWA-001 in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // // // Allow RWA-001 Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_RWA001);

        // // // Allow RWA-001 Flipper on the Cat
        CatAbstract(MCD_CAT).rely(MCD_FLIP_RWA001);

        // // // Allow cat to kick auctions in RWA-001 Flipper
        FlipAbstract(MCD_FLIP_RWA001).rely(MCD_CAT);

        // // // Allow End to yank auctions in RWA-001 Flipper
        // // TODO
        FlipAbstract(MCD_FLIP_RWA001).rely(MCD_END);
        
        // since we're adding 2 collateral types in this spell, global line is at beginning
        // TODO Line
        VatAbstract(MCD_VAT).file( ilk, "line", 10 * MILLION * RAD   ); // 10m debt ceiling
        VatAbstract(MCD_VAT).file( ilk, "dust", 100 * RAD            ); // 100 Dai dust
        CatAbstract(MCD_CAT).file( ilk, "dunk", 50 * THOUSAND * RAD  ); // 50,000 dunk
        CatAbstract(MCD_CAT).file( ilk, "chop", 100 * WAD / 100      ); // 0% liq. penalty
        JugAbstract(MCD_JUG).file( ilk, "duty", SIX_PCT_RATE         ); // 6% stability fee TODO ask matt

        // // note: nothing to file on the flipper 
        // FlipAbstract(MCD_FLIP_RWA001).file(  "beg" , 103 * WAD / 100      ); // 3% bid increase
        // FlipAbstract(MCD_FLIP_RWA001).file(  "ttl" , 6 hours              ); // 6 hours ttl
        // FlipAbstract(MCD_FLIP_RWA001).file(  "tau" , 6 hours              ); // 6 hours tau

        // // note: collateralization ratio ??
        // SpotAbstract(MCD_SPOT).file(ilk, "mat",  100 * RAY / 100     ); // 150% coll. ratio

        // note: no poke
        // SpotAbstract(MCD_SPOT).poke(ilk);

        // DOC hash?
        bytes32 doc = "doc";

        // init the RwaLiquidationOracle

        // liquidation oracle
        oracle.init(ilk, doc, PIP, 172800);

        // note: no ilk registry right now
        // IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_RWA001);
    }
}

contract RwaSpell {

    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // DSPauseAbstract public pause = DSPauseAbstract(0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
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
