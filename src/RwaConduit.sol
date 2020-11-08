pragma solidity 0.5.12;

interface GemLike {
    function transfer(address,uint) external returns (bool);
}


contract RwaConduit {
    GemLike public dai;
    address public to;

    constructor(address _dai, address _to) public {
        dai = GemLike(_dai);
        to = _to;
    }

    function push() public {
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}
