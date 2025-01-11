// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibSkill, Rating} from "../LibSkill.sol";

contract ExampleTeam {
    mapping(address => Rating) public ratingOf;

    function init() public {
        ratingOf[msg.sender] = LibSkill.rating();
    }

    function fight(address opponent) public {
        require(ratingOf[opponent].mu > 0, "opponent not initialized");

        bool isWin = uint256(blockhash(block.number - 1)) % 2 == 0;

        Rating[] memory ratings = new Rating[](2);
        ratings[0] = ratingOf[msg.sender];
        ratings[1] = ratingOf[opponent];

        uint256[] memory ranks = new uint256[](2);
        ranks[0] = isWin ? 0 : 1;
        ranks[1] = isWin ? 1 : 0;

        Rating[] memory nextRatings = LibSkill.updateArenaRatings(ratings, ranks);
        ratingOf[msg.sender] = nextRatings[0];
        ratingOf[opponent] = nextRatings[1];
    }
}
