pragma solidity >=0.5.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-math/math.sol";

import {Vat} from "dss/vat.sol";

import {Spotter} from "dss/spot.sol";

import {DaiJoin} from 'dss/join.sol';
import {AuthGemJoin} from "dss-gem-joins/join-auth.sol";

import {RwaToken} from "../RwaToken.sol";
import {RwaInputConduit, RwaOutputConduit} from "../RwaConduit.sol";
import {RwaLiquidationOracle} from "../RwaLiquidationOracle.sol";
import {RwaUrn} from "../RwaUrn.sol";

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

contract TryCaller {
    function do_call(address addr, bytes calldata data) external returns (bool) {
        bytes memory _data = data;
        assembly {
            let ok := call(gas(), addr, 0, add(_data, 0x20), mload(_data), 0, 0)
            let free := mload(0x40)
            mstore(free, ok)
            mstore(0x40, add(free, 32))
            revert(free, 32)
        }
    }

    function try_call(address addr, bytes calldata data) external returns (bool ok) {
        (, bytes memory returned) = address(this).call(abi.encodeWithSignature("do_call(address,bytes)", addr, data));
        ok = abi.decode(returned, (bool));
    }
}

contract RwaUser is TryCaller {
    RwaUrn urn;
    RwaOutputConduit outC;
    RwaInputConduit inC;

    constructor(RwaUrn urn_, RwaOutputConduit outC_, RwaInputConduit inC_)
        public {
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
    function can_pick(address who) public returns (bool ok) {
        ok = this.try_call(
            address(outC),
            abi.encodeWithSignature("pick(address)", who)
        );
    }
    function can_draw(uint256 wad) public returns (bool ok) {
        ok = this.try_call(
            address(urn),
            abi.encodeWithSignature("draw(uint256)", wad)
        );
    }
    function can_free(uint256 wad) public returns (bool ok) {
        ok = this.try_call(
            address(urn),
            abi.encodeWithSignature("free(uint256)", wad)
        );
    }
}

contract TryPusher is TryCaller {
    function can_push(address wat) public returns (bool ok) {
        ok = this.try_call(
            address(wat),
            abi.encodeWithSignature("push()")
        );
    }
}

contract RwaExampleTest is DSTest, DSMath, TryPusher {
    Hevm hevm;

    DSToken gov;
    DSToken dai;
    RwaToken rwa;

    Vat vat;
    address vow = address(123);;
    Spotter spotter;

    DaiJoin daiJoin;
    AuthGemJoin gemJoin;

    RwaLiquidationOracle oracle;
    RwaUrn urn;

    RwaOutputConduit outConduit;
    RwaInputConduit inConduit;

    RwaUser usr;
    RwaUltimateRecipient rec;

    // debt ceiling of 400 dai
    uint256 ceiling = 400 ether;
    string doc = "Please sign on the dotted line.";

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

        spotter = new Spotter(address(vat));
        vat.rely(address(spotter));

        dai = new DSToken("Dai");
        daiJoin = new DaiJoin(address(vat), address(dai));
        vat.rely(address(daiJoin));
        dai.setOwner(address(daiJoin));

        // the first RWA ilk is Acme Real World Assets Corporation
        vat.init("acme");
        vat.file("Line", 100 * rad(ceiling));
        vat.file("acme", "line", rad(ceiling));

        oracle = new RwaLiquidationOracle(address(vat), vow);
        oracle.init(
            "acme",
            wmul(ceiling, 1.1 ether),
            doc,
            2 weeks);
        vat.rely(address(oracle));
        (,address pip,,) = oracle.ilks("acme");

        spotter.file("acme", "mat", RAY);
        spotter.file("acme", "pip", pip);
        spotter.poke("acme");

        gemJoin = new AuthGemJoin(address(vat), "acme", address(rwa));
        vat.rely(address(gemJoin));

        // deploy output dai conduit
        outConduit = new RwaOutputConduit(address(gov), address(dai));
        // deploy urn
        urn = new RwaUrn(address(vat), address(gemJoin), address(daiJoin), address(outConduit));
        gemJoin.rely(address(urn));
        // deploy input dai conduit, pointed permanently at the urn
        inConduit = new RwaInputConduit(address(gov), address(dai), address(urn));

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

    function test_unpick_and_pick_new_rec() public {
        // lock some acme and draw some dai
        usr.lock(1 ether);
        usr.draw(400 ether);

        // the dai can be pushed
        assertTrue(can_push(address(outConduit)));

        // unpick current rec
        usr.pick(address(0));

        // dai can't move
        assertTrue(! can_push(address(outConduit)));

        // deploy and whitelist new rec
        RwaUltimateRecipient newrec = new RwaUltimateRecipient(dai);
        outConduit.kiss(address(newrec));

        usr.pick(address(newrec));
        outConduit.push();

        assertEq(dai.balanceOf(address(newrec)), 400 ether);
    }

    function test_cant_pick_unkissed_rec() public {
        RwaUltimateRecipient newrec = new RwaUltimateRecipient(dai);
        assertTrue(! usr.can_pick(address(newrec)));
    }

    function test_lock_and_draw() public {
        // check initial balances
        assertEq(dai.balanceOf(address(outConduit)), 0);
        assertEq(dai.balanceOf(address(rec)), 0);

        usr.lock(1 ether);
        usr.draw(400 ether);

        // check the amount went to the output conduit
        assertEq(dai.balanceOf(address(outConduit)), 400 ether);
        assertEq(dai.balanceOf(address(rec)), 0);

        // push the amount to the receiver
        outConduit.push();
        assertEq(dai.balanceOf(address(outConduit)), 0);
        assertEq(dai.balanceOf(address(rec)), 400 ether);
    }

    function test_draw_exceeds_debt_ceiling() public {
        usr.lock(1 ether);
        assertTrue(! usr.can_draw(500 ether));
    }

    function test_cant_draw_unless_hoped() public {
        usr.lock(1 ether);

        RwaUser rando = new RwaUser(urn, outConduit, inConduit);
        assertTrue(! rando.can_draw(100 ether));

        urn.hope(address(rando));
        assertEq(dai.balanceOf(address(outConduit)), 0);
        rando.draw(100 ether);
        assertEq(dai.balanceOf(address(outConduit)), 100 ether);
    }

    function test_partial_repay() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        outConduit.push();

        rec.transfer(address(inConduit), 100 ether);
        assertEq(dai.balanceOf(address(inConduit)), 100 ether);

        inConduit.push();
        usr.wipe(100 ether);
        assertTrue(! usr.can_free(1 ether));
        usr.free(0.1 ether);

        (uint ink, uint art) = vat.urns("acme", address(urn));
        assertEq(art, 300 ether);
        assertEq(ink, 0.9 ether);
        assertEq(dai.balanceOf(address(inConduit)), 0 ether);
    }

    function test_full_repay() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        outConduit.push();

        rec.transfer(address(inConduit), 400 ether);

        inConduit.push();
        usr.wipe(400 ether);
        usr.free(1 ether);

        (uint ink, uint art) = vat.urns("acme", address(urn));
        assertEq(art, 0);
        assertEq(ink, 0);
        assertEq(rwa.balanceOf(address(usr)), 1 ether);
    }

    function test_oracle_cure() public {
        usr.lock(1 ether);
        assertTrue(usr.can_draw(10 ether));

        // flash the liquidation beacon
        vat.file("acme", "line", rad(0));
        oracle.tell("acme");

        // not able to borrow
        assertTrue(! usr.can_draw(10 ether));

        hevm.warp(block.timestamp + 1 weeks);

        oracle.cure("acme");
        vat.file("acme", "line", rad(ceiling));
        assertTrue(oracle.good("acme"));

        // able to borrow
        assertEq(dai.balanceOf(address(rec)), 0);
        usr.draw(100 ether);
        outConduit.push();
        assertEq(dai.balanceOf(address(rec)), 100 ether);
    }

    function test_oracle_cull() public {
        usr.lock(1 ether);
        // not at full utilisation
        usr.draw(200 ether);

        // flash the liquidation beacon
        vat.file("acme", "line", rad(0));
        oracle.tell("acme");

        // not able to borrow
        assertTrue(! usr.can_draw(10 ether));

        hevm.warp(block.timestamp + 1 weeks);
        // still in remeditation period
        assertTrue(oracle.good("acme"));

        hevm.warp(block.timestamp + 2 weeks);

        assertEq(vat.gem("acme", address(oracle)), 0);
        // remediation period has elapsed
        assertTrue(! oracle.good("acme"));
        oracle.cull("acme", address(urn));

        assertTrue(! usr.can_draw(10 ether));

        (uint ink, uint art) = vat.urns("acme", address(urn));
        assertEq(ink, 0);
        assertEq(art, 0);

        assertEq(vat.sin(vow), rad(200 ether));

        // after the write-off, the gem goes to the oracle
        assertEq(vat.gem("acme", address(oracle)), 1 ether);

        spotter.poke("acme");
        (,,uint256 spot ,,) = vat.ilks("acme");
        assertEq(spot, 0);
    }

    function test_oracle_unremedied_loan_is_not_good() public {
        usr.lock(1 ether);
        usr.draw(200 ether);

        vat.file("acme", "line", 0);
        oracle.tell("acme");
        assertTrue(oracle.good("acme"));

        hevm.warp(block.timestamp + 3 weeks);
        assertTrue(! oracle.good("acme"));
    }

    function test_oracle_cull_two_urns() public {
        RwaUrn urn2 = new RwaUrn(
            address(vat),
            address(gemJoin),
            address(daiJoin),
            address(outConduit)
        );
        gemJoin.rely(address(urn2));
        RwaUser usr2 = new RwaUser(urn2, outConduit, inConduit);
        usr.approve(rwa, address(this), uint(-1));
        rwa.transferFrom(address(usr), address(usr2), 0.5 ether);
        usr2.approve(rwa, address(urn2), uint(-1));
        urn2.hope(address(usr2));
        usr.lock(0.5 ether);
        usr2.lock(0.5 ether);
        usr.draw(100 ether);
        usr2.draw(100 ether);

        assertTrue(usr.can_draw(1 ether));
        assertTrue(usr2.can_draw(1 ether));

        vat.file("acme", "line", 0);
        oracle.tell("acme");

        assertTrue(! usr.can_draw(1 ether));
        assertTrue(! usr2.can_draw(1 ether));

        hevm.warp(block.timestamp + 3 weeks);

        oracle.cull("acme", address(urn));
        assertEq(vat.sin(vow), rad(100 ether));
        oracle.cull("acme", address(urn2));
        assertEq(vat.sin(vow), rad(200 ether));
    }

    function test_oracle_bump() public {
        usr.lock(1 ether);
        usr.draw(400 ether);

        outConduit.push();

        // can't borrow more, ceiling exceeded
        assertTrue(! usr.can_draw(1 ether));

        // increase ceiling by 200 dai
        vat.file("acme", "line", rad(ceiling + 200 ether));

        // still can't borrow much more, vault is unsafe
        assertTrue(usr.can_draw(1 ether));
        assertTrue(! usr.can_draw(200 ether));

        // bump the price of acme
        oracle.bump("acme", wmul(ceiling + 200 ether, 1.1 ether));
        spotter.poke("acme");

        usr.draw(200 ether);
        outConduit.push();

        assertEq(dai.balanceOf(address(rec)), 600 ether);
    }
}
