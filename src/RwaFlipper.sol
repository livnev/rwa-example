pragma solidity >=0.5.12;

interface VatLike {
    function flux(bytes32,address,address,uint) external;
}

interface CatLike {
    function claw(uint256) external;
}

contract RwaFlipper {
    // --- auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaFlipper/not-authorized");
        _;
    }

    VatLike public vat;
    CatLike public cat;
    bytes32 public ilk;
    uint256 public kicks = 0;


    // --- init ---
    constructor(address vat_, address cat_, bytes32 ilk_) public {
        vat = VatLike(vat_);
        cat = CatLike(cat_);
        ilk = ilk_;
        wards[msg.sender] = 1;
    }

    function file(bytes32 what, address data) external note auth {
        if (what == "cat") cat = CatLike(data);
        else revert("RwaFlipper/file-unrecognized-param");
    }

    function kick(
        address usr,
        address gal,
        uint tab,
        uint lot,
        uint bid
    ) public auth returns (uint id) {
        require(kicks < uint(-1), "RwaFlipper/overflow");
        id = ++kicks;

        usr; gal; bid;
        vat.flux(ilk, msg.sender, address(this), lot);
        cat.claw(tab);
    }
}
