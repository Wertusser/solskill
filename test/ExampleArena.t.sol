// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ExampleArena} from "../src/examples/ExampleArena.sol";

contract ExampleArenaTest is Test {
    ExampleArena arena;

    function setUp() public {
        arena = new ExampleArena();
    }

    function testFuzz_arena(address[] memory opponents) public {
        for (uint256 i = 0; i < opponents.length; i++) {
            address opponent = opponents[i];
            vm.assume(opponent != address(0));
            arena.fight(opponent);
        }

        // Add assertions to verify the fight results
    }
}
