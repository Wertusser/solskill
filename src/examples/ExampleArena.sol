// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibSkill, Rating} from "../LibSkill.sol";

contract ExampleArena {
    mapping(address => Rating) public ratingOf;

    function init() public {
        _init(msg.sender);
    }

    function _init(address player) internal returns (Rating memory rating) {
        rating = LibSkill.rating();
        ratingOf[player] = rating;
    }

    function fight(address opponent) public {
        Rating memory ratingA = ratingOf[msg.sender];
        if (ratingA.mu == 0) ratingA = _init(msg.sender);

        Rating memory ratingB = ratingOf[opponent];
        if (ratingB.mu == 0) ratingB = _init(opponent);

        bool isWin = uint256(blockhash(block.number - 1)) % 2 == 0;

        Rating[] memory ratings = new Rating[](2);
        ratings[0] = ratingA;
        ratings[1] = ratingB;

        uint256[] memory ranks = new uint256[](2);
        ranks[0] = isWin ? 1 : 0;
        ranks[1] = isWin ? 0 : 1;

        Rating[] memory nextRatings =
            LibSkill.updateArenaRatings(ratings, ranks);
        ratingOf[msg.sender] = nextRatings[0];
        ratingOf[opponent] = nextRatings[1];
    }
}
