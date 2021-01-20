pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-math/math.sol";

import {Vat} from "dss/vat.sol";
import {Cat} from 'dss/cat.sol';
import {Vow} from 'dss/vow.sol';

import {Spotter} from "dss/spot.sol";
import {Flopper} from 'dss/flop.sol';
import {Flapper} from 'dss/flap.sol';

import {DaiJoin} from 'dss/join.sol';
import {AuthGemJoin} from "dss-gem-joins/join-auth.sol";

import {RwaToken} from "./RwaToken.sol";
import {RwaConduit, RwaRoutingConduit} from "./RwaConduit.sol";
import {RwaFlipper} from "./RwaFlipper.sol";
import {RwaLiquidationOracle} from "./RwaLiquidationOracle.sol";
import {RwaUrn} from "./RwaUrn.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

contract RwaUltimateRecipient {
    DSToken dai;
    constructor(DSToken dai_) public {
        dai = dai_;
    }
    function transfer(address who, uint256 wad) public {
        dai.transfer(who, wad);
    }
}

contract RwaUser {
    RwaUrn urn;
    RwaRoutingConduit outC;
    RwaConduit inC;

    constructor(RwaUrn urn_, RwaRoutingConduit outC_, RwaConduit inC_) public {
        urn = urn_;
        outC = outC_;
        inC = inC_;
    }

    function approve(RwaToken tok, address who, uint256 wad) public {
        tok.approve(who, wad);
    }
    function pick(address who) public {
        outC.pick(who);
    }
    function lock(uint256 wad) public {
        urn.lock(wad);
    }
    function free(uint256 wad) public {
        urn.free(wad);
    }
    function draw(uint256 wad) public {
        urn.draw(wad);
    }
    function wipe(uint256 wad) public {
        urn.wipe(wad);
    }
}

contract RwaExampleTest is DSTest, DSMath {
    Hevm hevm;

    DSToken gov;
    DSToken dai;
    RwaToken rwa;

    Vat vat;
    Vow vow;
    Cat cat;
    Spotter spot;

    Flapper flap;
    Flopper flop;

    DaiJoin daiJoin;
    AuthGemJoin gemJoin;

    RwaFlipper flip;
    RwaLiquidationOracle oracle;
    RwaUrn urn;

    RwaRoutingConduit outConduit;
    RwaConduit inConduit;

    RwaUser usr;
    RwaUltimateRecipient rec;

    // debt ceiling of 400 dai
    uint256 ceiling = 400 ether;
    bytes32 doc = keccak256(abi.encode("Please sign on the dotted line."));

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(604411200);

        // deploy governance token
        gov = new DSToken('GOV');
        gov.mint(100 ether);

        // deploy rwa token
        rwa = new RwaToken();

        // standard Vat setup
        vat = new Vat();

        spot = new Spotter(address(vat));
        vat.rely(address(spot));

        flap = new Flapper(address(vat), address(gov));
        flop = new Flopper(address(vat), address(gov));

        vow = new Vow(address(vat), address(flap), address(flop));
        flap.rely(address(vow));
        flop.rely(address(vow));

        cat = new Cat(address(vat));
        cat.file("vow", address(vow));
        cat.file("box", rad(10_000 ether));
        cat.file("acme", "chop", RAY);
        cat.file("acme", "dunk", rad(1_000_000 ether));
        vat.rely(address(cat));
        vow.rely(address(cat));

        dai = new DSToken("Dai");
        daiJoin = new DaiJoin(address(vat), address(dai));
        vat.rely(address(daiJoin));
        dai.setOwner(address(daiJoin));

        // the first RWA ilk is Acme Real World Assets Corporation
        vat.init("acme");
        vat.file("Line", rad(ceiling));
        vat.file("acme", "line", rad(ceiling));

        oracle = new RwaLiquidationOracle();
        oracle.init(
            "acme",
            wmul(ceiling, 1.1 ether),
            doc,
            2 weeks);
        (,address pip,,) = oracle.ilks("acme");

        spot.file("acme", "mat", RAY);
        spot.file("acme", "pip", pip);
        spot.poke("acme");

        flip = new RwaFlipper(address(vat), address(cat), "acme");
        flip.rely(address(cat));
        cat.file("acme", "flip", address(flip));
        cat.rely(address(flip));

        gemJoin = new AuthGemJoin(address(vat), "acme", address(rwa));
        vat.rely(address(gemJoin));

        // deploy outward dai conduit
        outConduit = new RwaRoutingConduit(address(gov), address(dai));
        // deploy urn
        urn = new RwaUrn(address(vat), address(gemJoin), address(daiJoin), address(outConduit));
        gemJoin.rely(address(urn));
        // deploy return dai conduit, pointed permanently at the urn
        inConduit = new RwaConduit(address(gov), address(dai), address(urn));

        // deploy user and ultimate dai recipient
        usr = new RwaUser(urn, outConduit, inConduit);
        rec = new RwaUltimateRecipient(dai);

        // fund user with rwa
        rwa.transfer(address(usr), 1 ether);

        // auth user to operate
        urn.hope(address(usr));
        outConduit.hope(address(usr));
        outConduit.kiss(address(rec));

        // usr nominates ultimate recipient
        usr.pick(address(rec));
        usr.approve(rwa, address(urn), uint(-1));
    }

    function test_lock_and_draw() public {
        usr.lock(1 ether);
        usr.draw(400 ether);
        assertEq(dai.balanceOf(address(outConduit)), 400 ether);

        outConduit.push();
        assertEq(dai.balanceOf(address(rec)), 400 ether);
    }

    function test_partial_repay() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        outConduit.push();

        rec.transfer(address(inConduit), 100 ether);
        assertEq(dai.balanceOf(address(inConduit)), 100 ether);

        inConduit.push();
        usr.wipe(100 ether);
    }

    function test_oracle_cure() public {
        // flash the liquidation beacon
        oracle.tell("acme");

        hevm.warp(now + 1 weeks);

        oracle.cure("acme");
        assertTrue(oracle.good("acme"));
    }

    function test_oracle_cull_and_flip() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        // flash the liquidation beacon
        oracle.tell("acme");

        hevm.warp(now + 2 weeks);

        oracle.cull("acme");
        assertTrue(! oracle.good("acme"));

        spot.poke("acme");
        cat.bite("acme", address(urn));

        (uint ink, uint art) = vat.urns("acme", address(urn));
        assertEq(ink, 0);
        assertEq(art, 0);

        assertEq(vat.sin(address(vow)), rad(400 ether));
    }

    function test_oracle_bump() public {
    }
}
