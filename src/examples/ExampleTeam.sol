// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibSkill, Rating} from "../LibSkill.sol";

contract ExampleTeam {
    mapping(address => Rating) public ratingOf;

    function init() public {
        _init(msg.sender);
    }

    function _init(address player) internal returns (Rating memory rating) {
        rating = LibSkill.rating();
        ratingOf[player] = rating;
    }

    function fight(address[] memory teamA, address[] memory teamB) public {
        require(teamA.length > 0, "teamA not initialized");
        require(teamB.length > 0, "teamB not initialized");

        bool isWin = uint256(blockhash(block.number - 1)) % 2 == 0;

        Rating[][] memory ratings = new Rating[][](2);
        ratings[0] = new Rating[](teamA.length);
        ratings[1] = new Rating[](teamB.length);

        for (uint256 i = 0; i < teamA.length; i++) {
            Rating memory rating = ratingOf[teamA[i]];
            if (rating.mu == 0) rating = _init(teamA[i]);
            ratings[0][i] = rating;
        }

        for (uint256 i = 0; i < teamB.length; i++) {
            Rating memory rating = ratingOf[teamB[i]];
            if (rating.mu == 0) rating = _init(teamB[i]);
            ratings[1][i] = rating;
        }

        uint256[] memory ranks = new uint256[](2);
        ranks[0] = isWin ? 0 : 1;
        ranks[1] = isWin ? 1 : 0;

        Rating[][] memory nextRatings =
            LibSkill.updateTeamRatings(ratings, ranks);

        for (uint256 i = 0; i < teamA.length; i++) {
            ratingOf[teamA[i]] = nextRatings[0][i];
        }

        for (uint256 i = 0; i < teamB.length; i++) {
            ratingOf[teamB[i]] = nextRatings[1][i];
        }
    }
}
