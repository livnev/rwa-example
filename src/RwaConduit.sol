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
