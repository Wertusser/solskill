// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ExampleTeam} from "../src/examples/ExampleTeam.sol";

contract ExampleTeamTest is Test {
    uint256 public constant MAX_PLAYERS = 5;
    ExampleTeam team;

    function setUp() public {
        team = new ExampleTeam();
    }

    function testFuzz_team(
        address[MAX_PLAYERS] memory teamA_,
        address[MAX_PLAYERS] memory teamB_
    ) public {
        address[] memory teamA = new address[](teamA_.length);
        address[] memory teamB = new address[](teamB_.length);

        for (uint256 i = 0; i < teamA_.length; i++) {
            vm.assume(teamA_[i] != address(0));
            teamA[i] = teamA_[i];
        }
        for (uint256 i = 0; i < teamB_.length; i++) {
            vm.assume(teamB_[i] != address(0));
            teamB[i] = teamB_[i];
        }
        team.fight(teamA, teamB);
        team.fight(teamA, teamB);
        team.fight(teamA, teamB);
    }
}
