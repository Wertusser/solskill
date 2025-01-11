// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {LibSkill, Rating} from "../src/LibSkill.sol";

contract LibSkillTest is Test {
    function setUp() public {}

    function showRatings(Rating[] memory rating) public pure {
        for (uint256 i = 0; i < rating.length; i++) {
            console.log("mu: ", rating[i].mu);
            console.log("sigma2: ", rating[i].sigma2);
            console.log("ordinal: ", LibSkill.ordinal(rating[i]));
            console.log("");
        }
    }

    function showRatings(Rating[][] memory rating) public pure {
        for (uint256 n = 0; n < rating.length; n++) {
            console.log("Team ", n);
            console.log("----------------");
            showRatings(rating[n]);
        }
    }

    function test_arena_2players() public pure {
        Rating[] memory ratings = new Rating[](2);
        ratings[0] = LibSkill.rating();
        ratings[1] = LibSkill.rating();

        uint256[] memory rank = new uint256[](2);
        rank[0] = 0;
        rank[1] = 1;

        showRatings(ratings);
        ratings = LibSkill.updateArenaRatings(ratings, rank);
        showRatings(ratings);
    }

    function test_arena_3players() public pure {
        Rating[] memory ratings = new Rating[](3);
        ratings[0] = LibSkill.rating();
        ratings[1] = LibSkill.rating();
        ratings[2] = LibSkill.rating();

        uint256[] memory rank = new uint256[](3);
        rank[0] = 0;
        rank[1] = 2;
        rank[2] = 1;

        showRatings(ratings);
        ratings = LibSkill.updateArenaRatings(ratings, rank);
        showRatings(ratings);
    }

    function test_arena_4players() public pure {
        Rating[] memory ratings = new Rating[](4);
        ratings[0] = LibSkill.rating();
        ratings[1] = LibSkill.rating();
        ratings[2] = LibSkill.rating();
        ratings[3] = LibSkill.rating();

        uint256[] memory rank = new uint256[](4);
        rank[0] = 0;
        rank[1] = 2;
        rank[2] = 1;
        rank[3] = 3;

        showRatings(ratings);
        ratings = LibSkill.updateArenaRatings(ratings, rank);
        showRatings(ratings);
    }

    function test_team_2v2() public pure {
        Rating[][] memory ratings = new Rating[][](2);
        ratings[0] = new Rating[](2);
        ratings[1] = new Rating[](2);

        ratings[0][0] = LibSkill.rating();
        ratings[0][1] = LibSkill.rating();
        ratings[1][0] = LibSkill.rating();
        ratings[1][1] = LibSkill.rating();

        uint256[] memory rank = new uint256[](2);
        rank[0] = 0;
        rank[1] = 2;

        showRatings(ratings);
        ratings = LibSkill.updateTeamRatings(ratings, rank);
        showRatings(ratings);
    }

    function test_team_2v2v2() public pure {
        Rating[][] memory ratings = new Rating[][](3);
        ratings[0] = new Rating[](2);
        ratings[1] = new Rating[](2);
        ratings[2] = new Rating[](2);

        ratings[0][0] = LibSkill.rating();
        ratings[0][1] = LibSkill.rating();
        ratings[1][0] = LibSkill.rating();
        ratings[1][1] = LibSkill.rating();
        ratings[2][0] = LibSkill.rating();
        ratings[2][1] = LibSkill.rating();

        uint256[] memory rank = new uint256[](3);
        rank[0] = 0;
        rank[1] = 2;
        rank[2] = 1;

        showRatings(ratings);
        ratings = LibSkill.updateTeamRatings(ratings, rank);
        showRatings(ratings);
    }

    function test_team_5v5() public pure {
        Rating[][] memory ratings = new Rating[][](2);
        ratings[0] = new Rating[](5);
        ratings[1] = new Rating[](5);

        ratings[0][0] = LibSkill.rating();
        ratings[0][1] = LibSkill.rating();
        ratings[0][2] = LibSkill.rating();
        ratings[0][3] = LibSkill.rating();
        ratings[0][4] = LibSkill.rating();

        ratings[1][0] = LibSkill.rating();
        ratings[1][1] = LibSkill.rating();
        ratings[1][2] = LibSkill.rating();
        ratings[1][3] = LibSkill.rating();
        ratings[1][4] = LibSkill.rating();

        uint256[] memory rank = new uint256[](2);
        rank[0] = 0;
        rank[1] = 2;

        showRatings(ratings);
        ratings = LibSkill.updateTeamRatings(ratings, rank);
        showRatings(ratings);
    }
}
