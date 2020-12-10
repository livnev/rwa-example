pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";
import "./test/rates.sol";

import {RwaSpell, SpellAction} from "./RwaSpell.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

pragma solidity >=0.5.12;

// https://github.com/dapphub/ds-chief
interface DSChief2 {
    function live() external view returns (uint256);
    function launch() external;
    function slates(bytes32) external view returns (address[] memory);
    function votes(address) external view returns (bytes32);
    function approvals(address) external view returns (uint256);
    function deposits(address) external view returns (address);
    function hat() external view returns (address);
    function lock(uint256) external;
    function free(uint256) external;
    function etch(address[] calldata) external returns (bytes32);
    function vote(address[] calldata) external returns (bytes32);
    function vote(bytes32) external;
    function lift(address) external;
}

interface RwaUrnLike {
    function can(address) external returns (uint);
    function rely(address) external;
    function deny(address) external;
    function hope(address) external;
    function nope(address) external;
    function file(bytes32, address) external;
    function lock(uint256) external;
    function free(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
}

interface RwaLiquidationLike {
    function wards(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external returns (bytes32, address, uint48, uint48);
    function init(bytes32, bytes32, address, uint48) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32) external;
    function good(bytes32) external view returns (bool);
}

contract EndSpellAction {
    EndAbstract constant end = EndAbstract(0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F);

    function execute() public {
        end.cage();
    }
}

contract EndSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new EndSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
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

contract OperatorSpellAction {
    RwaUrnLike constant rwaurn = RwaUrnLike(0x0aB030EF81948dFc40aA6001625801921609D7c6);
    bytes32 constant ilk = "RWA-001";
    address test;

    constructor(address _test) public {
        test = _test;
    }

    function execute() public {
        rwaurn.hope(test);
    }
}

contract OperatorSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor(address _test) public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new OperatorSpellAction(_test));
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
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

contract CullSpellAction {
    RwaLiquidationLike constant rwapip  = RwaLiquidationLike(0x51486fbD0e669b48eA28Dee273Fac5F89402f982);
    bytes32 constant ilk = "RWA-001";

    function execute() public {
        rwapip.cull(ilk);
    }
}

contract CullSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new CullSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
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

contract CureSpellAction {
    RwaLiquidationLike constant rwapip  = RwaLiquidationLike(0x51486fbD0e669b48eA28Dee273Fac5F89402f982);
    bytes32 constant ilk = "RWA-001";

    function execute() public {
        rwapip.cure(ilk);
    }
}

contract CureSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new CureSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
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

contract TellSpellAction {
    RwaLiquidationLike constant rwapip  = RwaLiquidationLike(0x51486fbD0e669b48eA28Dee273Fac5F89402f982);
    bytes32 constant ilk = "RWA-001";

    function execute() public {
        rwapip.tell(ilk);
    }
}

contract TellSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new TellSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
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

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant KOVAN_SPELL = address(0);
    // this needs to be updated
    uint256 constant SPELL_CREATED = 1606154989 ;

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 chop;
        uint256 dunk;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48 ttl;
        uint48 tau;
        uint256 liquidations;
    }

    struct SystemValues {
        uint256 pot_dsr;
        uint256 vat_Line;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump;
        uint256 cat_box;
        address osm_mom_authority;
        address flipper_mom_authority;
        uint256 ilk_count;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues afterSpell;

    Hevm hevm;
    Rates rates;

    bytes32 constant ilk = "RWA-001";

    // KOVAN ADDRESSES
    DSPauseAbstract      pause = DSPauseAbstract(    0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
    address         pauseProxy =                     0x0e4725db88Bb038bBa4C4723e91Ba183BE11eDf3;

    DSChief2 chief = DSChief2(    0x27E0c9567729Ea6e3241DE74B3dE499b7ddd3fe6);
    VatAbstract            vat = VatAbstract(        0xbA987bDB501d131f766fEe8180Da5d81b34b69d9);

    CatAbstract            cat = CatAbstract(        0xdDb5F7A3A5558b9a6a1f3382BD75E2268d1c6958);
    JugAbstract            jug = JugAbstract(        0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD);

    VowAbstract            vow = VowAbstract(        0x0F4Cbe6CBA918b7488C26E29d9ECd7368F38EA3b);
    PotAbstract            pot = PotAbstract(        0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);

    SpotAbstract          spot = SpotAbstract(       0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D);
    DSTokenAbstract        gov = DSTokenAbstract(    0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD);

    EndAbstract            end = EndAbstract(        0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F);
    IlkRegistryAbstract    reg = IlkRegistryAbstract(0xedE45A0522CA19e979e217064629778d6Cc2d9Ea);

    OsmMomAbstract      osmMom = OsmMomAbstract(     0x5dA9D1C3d4f1197E5c52Ff963916Fe84D2F5d8f3);
    FlipperMomAbstract flipMom = FlipperMomAbstract( 0x50dC6120c67E456AdA2059cfADFF0601499cf681);

    ChainlogAbstract chainlog  = ChainlogAbstract(   0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address constant RWA001_GEM      = 0xF1c74E2970E86cEC267b1714b2919f8A105Fb526;
    address constant MCD_JOIN_RWA001 = 0x0963237D0CBa02D9ee64f2a2f777f2eAeB7C3819;
    address constant MCD_FLIP_RWA001 = 0x8022Fd8a28A3acCE3C45bBbca8d3B7B972700153;
    address constant PIP_RWA001      = 0x51486fbD0e669b48eA28Dee273Fac5F89402f982;
    address constant PIP             = 0x0318D82C3b2a23d993dcE881aada122f311ca901;
    address constant RWA_URN         = 0x54E0C515c0E804Ffea62559eFdDDe8CB03188044;

    DSTokenAbstract constant rwagem     = DSTokenAbstract(RWA001_GEM);
    GemJoinAbstract constant rwajoin    = GemJoinAbstract(MCD_JOIN_RWA001);
    FlipAbstract constant rwaflip       = FlipAbstract(MCD_FLIP_RWA001);
    RwaLiquidationLike constant rwapip  = RwaLiquidationLike(PIP_RWA001);
    RwaUrnLike constant rwaurn          = RwaUrnLike(RWA_URN);

    address    makerDeployer06 =                     0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711;

    // rwa specific

    // // MAINNET ADDRESSES
    // DSPauseAbstract      pause = DSPauseAbstract(    0xbE286431454714F511008713973d3B053A2d38f3);
    // address         pauseProxy =                     0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    // DSChief2 chief = DSChief2(    0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    // VatAbstract            vat = VatAbstract(        0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    // CatAbstract            cat = CatAbstract(        0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea);
    // JugAbstract            jug = JugAbstract(        0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    // VowAbstract            vow = VowAbstract(        0xA950524441892A31ebddF91d3cEEFa04Bf454466);

    // PotAbstract            pot = PotAbstract(        0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);

    // SpotAbstract          spot = SpotAbstract(       0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    // DSTokenAbstract        gov = DSTokenAbstract(    0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    // EndAbstract            end = EndAbstract(        0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    // IlkRegistryAbstract    reg = IlkRegistryAbstract(0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24);

    // OsmMomAbstract      osmMom = OsmMomAbstract(     0x76416A4d5190d071bfed309861527431304aA14f);
    // FlipperMomAbstract flipMom = FlipperMomAbstract( 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472);

    // ChainlogAbstract chainlog  = ChainlogAbstract(   0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    RwaSpell spell;
    TellSpell tellSpell;
    CureSpell cureSpell;
    CullSpell cullSpell;
    OperatorSpell operatorSpell;
    EndSpell endSpell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant HUNDRED    = 10 ** 2;
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;
    uint256 constant BILLION    = 10 ** 9;
    uint256 constant WAD        = 10 ** 18;
    uint256 constant RAY        = 10 ** 27;
    uint256 constant RAD        = 10 ** 45;

    event Debug(uint256 index, uint256 val);
    event Debug(uint256 index, address addr);
    event Debug(uint256 index, bytes32 what);

    // not provided in DSMath
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
    // 10^-5 (tenth of a basis point) as a RAY
    uint256 TOLERANCE = 10 ** 22;

    function yearlyYield(uint256 duty) public pure returns (uint256) {
        return rpow(duty, (365 * 24 * 60 *60), RAY);
    }

    function expectedRate(uint256 percentValue) public pure returns (uint256) {
        return (10000 + percentValue) * (10 ** 23);
    }

    function diffCalc(uint256 expectedRate_, uint256 yearlyYield_) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ? expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        rates = new Rates();

        spell = KOVAN_SPELL != address(0) ? RwaSpell(KOVAN_SPELL) : new RwaSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr:               0,                       // In basis points
            vat_Line:              12320 * MILLION / 100,  // In whole Dai units
            pause_delay:           60,                // In seconds
            vow_wait:              3600,               // In seconds
            vow_dump:              2,                     // In whole Dai units
            vow_sump:              50,                   // In whole Dai units
            vow_bump:              10,                   // In whole Dai units
            vow_hump:              500,             // In whole Dai units
            cat_box:               10 * THOUSAND,            // In whole Dai units
            osm_mom_authority:     address(0),              // OsmMom authority
            flipper_mom_authority: address(0),              // FlipperMom authority
            ilk_count:             18                       // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["RWA-001"] = CollateralValues({
            line:         490 * MILLION,   // In whole Dai units
            dust:         100,             // In whole Dai units
            pct:          200,             // In basis points
            chop:         1300,            // In basis points
            dunk:         50 * THOUSAND,   // In whole Dai units
            mat:          15000,           // In basis points
            beg:          300,             // In basis points
            ttl:          6 hours,         // In seconds
            tau:          6 hours,         // In seconds
            liquidations: 1                // 1 if enabled
        });
    }

    function scheduleWaitAndCastFailDay() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 day = (castTime / 1 days + 3) % 7;
        if (day < 5) {
            castTime += 5 days - day * 86400;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailEarly() public {
        spell.schedule();

        uint256 castTime = now + pause.delay() + 24 hours;
        uint256 hour = castTime / 1 hours % 24;
        if (hour >= 14) {
            castTime -= hour * 3600 - 13 hours;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailLate() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 hour = castTime / 1 hours % 24;
        if (hour < 21) {
            castTime += 21 hours - hour * 3600;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(chief), uint256(-1));
            chief.lock(sub(gov.balanceOf(address(this)), 1 ether));

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(address(spell));
        }
        assertEq(chief.hat(), address(spell));
    }

    function voteTemp(address _spell) private {
        if (chief.hat() != address(_spell)) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(chief), uint256(-1));
            chief.lock(sub(gov.balanceOf(address(this)), 1 ether));

            DSSpellAbstract tempSpell = DSSpellAbstract(_spell);

            assertTrue(!tempSpell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(_spell);

            chief.vote(yays);
            chief.lift(address(_spell));
        }
        assertEq(chief.hat(), address(_spell));
    }

    function scheduleWaitAndCast() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();

        // uint256 day = (castTime / 1 days + 3) % 7;
        // if(day >= 5) {
        //     castTime += 7 days - day * 86400;
        // }

        // uint256 hour = castTime / 1 hours % 24;
        // if (hour >= 21) {
        //     castTime += 24 hours - hour * 3600 + 14 hours;
        // } else if (hour < 14) {
        //     castTime += 14 hours - hour * 3600;
        // }

        hevm.warp(castTime);
        spell.cast();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function checkSystemValues(SystemValues storage values) internal {
        // dsr
        uint256 expectedDSRRate = rates.rates(values.pot_dsr);
        // make sure dsr is less than 100% APR
        // bc -l <<< 'scale=27; e( l(2.00)/(60 * 60 * 24 * 365) )'
        // 1000000021979553151239153027
        assertTrue(
            pot.dsr() >= RAY && pot.dsr() < 1000000021979553151239153027
        );
        assertTrue(diffCalc(expectedRate(values.pot_dsr), yearlyYield(expectedDSRRate)) <= TOLERANCE);

        {
        // Line values in RAD
        uint256 normalizedLine = values.vat_Line * RAD;
        assertEq(vat.Line(), normalizedLine);
        assertTrue(
            (vat.Line() >= RAD && vat.Line() < 100 * BILLION * RAD) ||
            vat.Line() == 0
        );
        }

        // Pause delay
        assertEq(pause.delay(), values.pause_delay);

        // wait
        assertEq(vow.wait(), values.vow_wait);

        {
        // dump values in WAD
        uint256 normalizedDump = values.vow_dump * WAD;
        assertEq(vow.dump(), normalizedDump);
        assertTrue(
            (vow.dump() >= WAD && vow.dump() < 2 * THOUSAND * WAD) ||
            vow.dump() == 0
        );
        }
        {
        // sump values in RAD
        uint256 normalizedSump = values.vow_sump * RAD;
        assertEq(vow.sump(), normalizedSump);
        assertTrue(
            (vow.sump() >= RAD && vow.sump() < 500 * THOUSAND * RAD) ||
            vow.sump() == 0
        );
        }
        {
        // bump values in RAD
        uint normalizedBump = values.vow_bump * RAD;
        assertEq(vow.bump(), normalizedBump);
        assertTrue(
            (vow.bump() >= RAD && vow.bump() < HUNDRED * THOUSAND * RAD) ||
            vow.bump() == 0
        );
        }
        {
        // hump values in RAD
        uint256 normalizedHump = values.vow_hump * RAD;
        assertEq(vow.hump(), normalizedHump);
        assertTrue(
            (vow.hump() >= RAD && vow.hump() < HUNDRED * MILLION * RAD) ||
            vow.hump() == 0
        );
        }

        // box values in RAD
        {
            uint256 normalizedBox = values.cat_box * RAD;
            assertEq(cat.box(), normalizedBox);
        }

        // check OsmMom authority
        assertEq(osmMom.authority(), values.osm_mom_authority);

        // check FlipperMom authority
        assertEq(flipMom.authority(), values.flipper_mom_authority);

        // check number of ilks
        assertEq(reg.count(), values.ilk_count);
    }

    function checkCollateralValues(SystemValues storage values) internal {
        uint256 sumlines;
        bytes32[] memory ilks = reg.list();
        for(uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            (uint256 duty,)  = jug.ilks(ilk);

            assertEq(duty, rates.rates(values.collaterals[ilk].pct));
            // make sure duty is less than 1000% APR
            // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
            // 1000000073014496989316680335
            assertTrue(duty >= RAY && duty < 1000000073014496989316680335);  // gt 0 and lt 1000%
            assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(rates.rates(values.collaterals[ilk].pct))) <= TOLERANCE);
            assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND);   // check value lt 1000%
            {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestLine = values.collaterals[ilk].line * RAD;
            sumlines += values.collaterals[ilk].line;
            assertEq(line, normalizedTestLine);
            assertTrue((line >= RAD && line < BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 1B
            uint256 normalizedTestDust = values.collaterals[ilk].dust * RAD;
            assertEq(dust, normalizedTestDust);
            assertTrue((dust >= RAD && dust < 10 * THOUSAND * RAD) || dust == 0); // eq 0 or gt eq 1 and lt 10k
            }
            {
            (, uint256 chop, uint256 dunk) = cat.ilks(ilk);
            // Convert BP to system expected value
            uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
            assertEq(chop, normalizedTestChop);
            // make sure chop is less than 100%
            assertTrue(chop >= WAD && chop < 2 * WAD);   // penalty gt eq 0% and lt 100%
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestDunk = values.collaterals[ilk].dunk * RAD;
            assertEq(dunk, normalizedTestDunk);
            // put back in after LIQ-1.2
            assertTrue(dunk >= RAD && dunk < MILLION * RAD);
            }
            {
            (,uint256 mat) = spot.ilks(ilk);
            // Convert BP to system expected value
            uint256 normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
            assertEq(mat, normalizedTestMat);
            assertTrue(mat >= RAY && mat < 10 * RAY);    // cr eq 100% and lt 1000%
            }
            {
            (address flipper,,) = cat.ilks(ilk);
            FlipAbstract flip = FlipAbstract(flipper);
            // Convert BP to system expected value
            uint256 normalizedTestBeg = (values.collaterals[ilk].beg + 10000)  * 10**14;
            assertEq(uint256(flip.beg()), normalizedTestBeg);
            assertTrue(flip.beg() >= WAD && flip.beg() < 105 * WAD / 100);  // gt eq 0% and lt 5%
            assertEq(uint256(flip.ttl()), values.collaterals[ilk].ttl);
            assertTrue(flip.ttl() >= 600 && flip.ttl() < 10 hours);         // gt eq 10 minutes and lt 10 hours
            assertEq(uint256(flip.tau()), values.collaterals[ilk].tau);
            assertTrue(flip.tau() >= 600 && flip.tau() <= 3 days);          // gt eq 10 minutes and lt eq 3 days

            assertEq(flip.wards(address(cat)), values.collaterals[ilk].liquidations);  // liquidations == 1 => on
            assertEq(flip.wards(address(makerDeployer06)), 0); // Check deployer denied
            assertEq(flip.wards(address(pauseProxy)), 1); // Check pause_proxy ward
            }
            {
            GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
            assertEq(join.wards(address(makerDeployer06)), 0); // Check deployer denied
            assertEq(join.wards(address(pauseProxy)), 1); // Check pause_proxy ward
            }
        }
        assertEq(sumlines, values.vat_Line);
    }

    // function testFailWrongDay() public {
    //     vote();
    //     scheduleWaitAndCastFailDay();
    // }

    // function testFailTooEarly() public {
    //     vote();
    //     scheduleWaitAndCastFailEarly();
    // }

    // function testFailTooLate() public {
    //     vote();
    //     scheduleWaitAndCastFailLate();
    // }

    function testSpellIsCast() public {
        string memory description = new RwaSpell().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description));

        if(address(spell) != address(KOVAN_SPELL)) {
            assertEq(spell.expiration(), (now + 30 days));
        } else {
            assertEq(spell.expiration(), (SPELL_CREATED + 30 days));
        }

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        // checkSystemValues(afterSpell);

        // checkCollateralValues(afterSpell);
    }

    // function testChainlogValues() public {
    //     vote();
    //     scheduleWaitAndCast();
    //     assertTrue(spell.done());

    //     // assertEq(chainlog.getAddress("FLIP_FAB"), 0x4ACdbe9dd0d00b36eC2050E805012b8Fc9974f2b);
    //     // assertEq(chainlog.getAddress("GUSD"), 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
    //     // assertEq(chainlog.getAddress("MCD_JOIN_GUSD_A"), 0xe29A14bcDeA40d83675aa43B72dF07f649738C8b);
    //     // assertEq(chainlog.getAddress("MCD_FLIP_GUSD_A"), 0xCAa8D152A8b98229fB77A213BE16b234cA4f612f);
    //     // assertEq(chainlog.getAddress("PIP_GUSD"), 0xf45Ae69CcA1b9B043dAE2C83A5B65Bc605BEc5F5);
    // }

    function testSpellIsCast_RWA001_INTEGRATION() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());
    }

    function testSpellIsCast_RWA001_INTEGRATION_TELL() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        tellSpell = new TellSpell();
        voteTemp(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = now + pause.delay();
        hevm.warp(castTime);
        tellSpell.cast();
        hevm.warp(172801);
        assertTrue(!rwapip.good("RWA-001"));
    }

    function testSpellIsCast_RWA001_INTEGRATION_TELL_CURE_GOOD() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        tellSpell = new TellSpell();
        voteTemp(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = now + pause.delay();
        hevm.warp(castTime);
        tellSpell.cast();
        hevm.warp(172801);
        assertTrue(!rwapip.good("RWA-001"));

        cureSpell = new CureSpell();
        voteTemp(address(cureSpell));

        cureSpell.schedule();
        castTime = now + pause.delay();
        hevm.warp(castTime);
        cureSpell.cast();
        assertTrue(rwapip.good("RWA-001"));
    }

    function testSpellIsCast_RWA001_INTEGRATION_TELL_CULL() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        tellSpell = new TellSpell();
        voteTemp(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = now + pause.delay();
        hevm.warp(castTime);
        tellSpell.cast();
        hevm.warp(172801);
        assertTrue(!rwapip.good("RWA-001"));

        cullSpell = new CullSpell();
        voteTemp(address(cullSpell));

        cullSpell.schedule();
        castTime = now + pause.delay();
        hevm.warp(castTime);
        cullSpell.cast();
        assertTrue(!rwapip.good("RWA-001"));
        assertEq(DSValueAbstract(PIP).read(), bytes32(0));
    }

    function testSpellIsCast_RWA001_OPERATOR_LOCK_FREE_DRAW_WIPE() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        // fix this
        hevm.store(
            address(rwagem),
            keccak256(abi.encode(address(this), uint256(4))),
            bytes32(uint256(1 ether))
        );
        // setting address(this) as operator
        hevm.store(
            address(rwaurn),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(1))
        );
        assertEq(rwagem.balanceOf(address(this)), 1 * WAD);
        assertEq(rwagem.totalSupply(), 2 * WAD);
        assertEq(rwaurn.can(address(this)), 1);

        rwagem.approve(address(rwaurn), 1 * WAD);
        rwaurn.lock(1 * WAD);
        // rwaurn.draw(1 ether);
        // rwaurn.wipe(1 ether);
        // rwaurn.free(1 ether);
    }

    function testSpellIsCast_RWA001_END() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        endSpell = new EndSpell();
        voteTemp(address(endSpell));

        endSpell.schedule();

        uint256 castTime = now + pause.delay();
        hevm.warp(castTime);
        endSpell.cast();

        // TODO: finish
    }

    // test end in 2 scenarios (if we need yank in flip contract?) think thru if we need yank in the clip?

    //  what to do if MCD isn't instantiated, if we don't give people the token big issue, token can trade on uni

    // would this end work with ETH? think of it very generally
}
