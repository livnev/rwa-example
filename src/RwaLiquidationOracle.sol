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
import 'ds-value/value.sol';

contract RwaLiquidationOracle {
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
        require(wards[msg.sender] == 1, "RwaLiquidationOracle/not-authorized");
        _;
    }

    // --- math ---
    function add(uint48 x, uint48 y) internal pure returns (uint48 z) {
        require((z = x + y) >= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    VatAbstract public vat;
    address     public vow;
    struct Ilk {
        bytes32 doc; // hash of borrower's agreement with MakerDAO
        address pip; // DSValue tracking nominal loan value
        uint48  tau; // pre-agreed remediation period
        uint48  toc; // timestamp when liquidation initiated
    }
    mapping (bytes32 => Ilk) public ilks;

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Init(bytes32 indexed ilk, uint256 val, bytes32 doc, uint48 tau);
    event Tell(bytes32 indexed ilk);
    event Cure(bytes32 indexed ilk);
    event Cull(bytes32 indexed ilk);
    event Bite(bytes32 indexed ilk, address indexed urn);

    constructor(address vat_, address vow_) public {
        vat = VatAbstract(vat_);
        vow = vow_;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function init(bytes32 ilk, uint256 val, bytes32 doc, uint48 tau) external auth {
        // doc, and tau can be amended, but tau cannot decrease
        require(tau >= ilks[ilk].tau);
        ilks[ilk].doc = doc;
        ilks[ilk].tau = tau;
        if (ilks[ilk].pip == address(0)) {
            DSValue pip = new DSValue();
            ilks[ilk].pip = address(pip);
            pip.poke(bytes32(val));
        }
        emit Init(ilk, val, doc, tau);
    }

    // --- valuation adjustment ---
    function bump(bytes32 ilk, uint256 val) external auth {
        DSValue pip = DSValue(ilks[ilk].pip);
        // only cull can decrease
        require(val >= uint256(pip.read()));
        DSValue(ilks[ilk].pip).poke(bytes32(val));
    }
    // --- liquidation ---
    function tell(bytes32 ilk) external auth {
        (,,,uint256 line,) = vat.ilks(ilk);
        // DC must be set to zero first
        require(line == 0);
        require(ilks[ilk].pip != address(0));
        ilks[ilk].toc = uint48(block.timestamp);
        emit Tell(ilk);
    }
    // --- remediation ---
    function cure(bytes32 ilk) external auth {
        ilks[ilk].toc = 0;
        emit Cure(ilk);
    }
    // --- write-off ---
    function cull(bytes32 ilk) external auth {
        require(add(ilks[ilk].toc, ilks[ilk].tau) >= block.timestamp);
        DSValue(ilks[ilk].pip).poke(bytes32(uint256(0)));
        emit Cull(ilk);
    }
    function bite(bytes32 ilk, address urn) external {
        require(vat.live() == 1, "Vat/not-live");
        require(ilks[ilk].pip != address(0), "RwaLiquidationOracle/not-Rwa-asset");

        (uint256 ink, uint256 art) = vat.urns(ilk, urn);
        (,uint256 rate,uint256 spot,,) = vat.ilks(ilk);
        require(mul(ink, spot) < mul(art, rate), "RwaLiquidationOracle/not-unsafe");

        require(ink <= 2 ** 255, "RwaLiquidationOracle/overflow");
        require(art <= 2 ** 255, "RwaLiquidationOracle/overflow");

        vat.grab(ilk,
                 address(urn),
                 address(urn),
                 address(vow),
                 -int256(ink),
                 -int256(art));
        emit Bite(ilk, urn);
    }

    // --- liquidation check ---
    // to be called by off-chain parties (e.g. a trustee) to check the standing of the loan
    function good(bytes32 ilk) external view returns (bool) {
        require(ilks[ilk].pip != address(0));
        return (ilks[ilk].toc == 0 || add(ilks[ilk].toc, ilks[ilk].tau) < block.timestamp);
    }
}
