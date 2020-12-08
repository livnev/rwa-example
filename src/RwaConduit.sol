pragma solidity 0.5.12;

interface GemLike {
    function transfer(address,uint256) external returns (bool);
    function balanceOf(address) external returns (uint256);
}

contract RwaConduit {
    GemLike public gov;
    GemLike public dai;
    address public to;

    constructor(address _gov, address _dai, address _to) public {
        gov = GemLike(_gov);
        dai = GemLike(_dai);
        to = _to;
    }

    function push() public {
        require(gov.balanceOf(msg.sender) > 0);
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}

contract RwaRoutingConduit {
    // --- auth ---
    mapping (address => uint) public wards;
    mapping (address => uint) public can;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaConduit/not-authorized");
        _;
    }
    function hope(address usr) external auth { can[usr] = 1; }
    function nope(address usr) external auth { can[usr] = 0; }
    modifier operator {
        require(can[msg.sender] == 1, "RwaConduit/not-operator");
        _;
    }

    GemLike public gov;
    GemLike public dai;

    address public to;
    mapping (address => uint) public bud;

    constructor(address _gov, address _dai) public {
        wards[msg.sender] = 1;
        gov = GemLike(_gov);
        dai = GemLike(_dai);
    }

    // --- administration ---
    function kiss(address who) public auth {
        bud[who] = 1;
    }
    function diss(address who) public auth {
        if (to == who) to = address(0);
        bud[who] = 0;
    }

    // --- routing ---
    function pick(address who) public operator {
        require(bud[who] == 1 || who == address(0), "RwaConduit/not-bud");
        to = who;
    }
    function push() public {
        require(to != address(0), "RwaConduit/to-not-set");
        require(gov.balanceOf(msg.sender) > 0, "RwaConduit/no-gov");
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}
