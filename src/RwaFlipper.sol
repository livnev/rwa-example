// Copyright (C) 2020, 2021 Lev Livnev <lev@liv.nev.org.uk>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";

contract RwaFlipper {
    // --- auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaFlipper/not-authorized");
        _;
    }

    VatAbstract public vat;
    CatAbstract public cat;
    bytes32 public ilk;
    uint256 public kicks = 0;

    // Events
    event Rely(address usr);
    event Deny(address usr);
    event File(bytes32 what, address data);
    event Kick(
        uint256 id,
        uint256 lot,
        uint256 bid,
        uint256 tab,
        address indexed usr,
        address indexed gal
    );

    // --- init ---
    constructor(address vat_, address cat_, bytes32 ilk_) public {
        vat = VatAbstract(vat_);
        cat = CatAbstract(cat_);
        ilk = ilk_;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "cat") {
            cat = CatAbstract(data);
            emit File(what, data);
        }
        else revert("RwaFlipper/file-unrecognized-param");
    }

    function kick(
        address usr,
        address gal,
        uint256 tab,
        uint256 lot,
        uint256 bid
    ) public auth returns (uint256 id) {
        require(kicks < uint256(-1), "RwaFlipper/overflow");
        id = ++kicks;

        usr; gal; bid;
        vat.flux(ilk, msg.sender, address(this), lot);
        cat.claw(tab);
        emit Kick(id, lot, bid, tab, usr, gal);
    }
}
