// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LibSkill, Rating} from "../src/LibSkill.sol";

contract LibSkillTest is Test {
    int256 private constant WAD = 1e18;
    uint256 private constant REFERENCE_TOLERANCE = 1e14;

    // Values generated with OpenSkill JS v5.0.1, bradleyTerryFull, tau: 0.
    function testArenaMatchesOpenSkillTwoPlayerVector() public {
        Rating[] memory players = _defaultPlayers(2);
        uint256[] memory ranks = new uint256[](2);
        ranks[1] = 1;

        Rating[] memory next = LibSkill.updateArenaRatings(players, ranks);

        _assertRatingApprox(next[0], 27635231383473650000, 65052392138655050000);
        _assertRatingApprox(next[1], 22364768616526350000, 65052392138655050000);
    }

    function testArenaMatchesOpenSkillThreePlayerVector() public {
        Rating[] memory players = _defaultPlayers(3);
        uint256[] memory ranks = new uint256[](3);
        ranks[1] = 2;
        ranks[2] = 1;

        Rating[] memory next = LibSkill.updateArenaRatings(players, ranks);

        _assertRatingApprox(next[0], 30270462766947300000, 60660339832865600000);
        _assertRatingApprox(next[1], 19729537233052700000, 60660339832865600000);
        _assertRatingApprox(next[2], 25000000000000000000, 60660339832865600000);
    }

    function testArenaDrawMatchesOpenSkillVector() public {
        Rating[] memory players = new Rating[](2);
        players[0] = _rating(32444000000000000000, 26245129000000000000);
        players[1] = _rating(43381000000000000000, 5861241000000000000);
        uint256[] memory ranks = new uint256[](2);

        Rating[] memory next = LibSkill.updateArenaRatings(players, ranks);

        _assertRatingApprox(next[0], 33381907749185860000, 25181599410960720000);
        _assertRatingApprox(next[1], 43171540052070390000, 5836174035557568000);
    }

    function testArenaOutputIsPermutationInvariant() public {
        Rating[] memory players = new Rating[](3);
        players[0] = _rating(20000000000000000000, 40000000000000000000);
        players[1] = _rating(30000000000000000000, 90000000000000000000);
        players[2] = _rating(25000000000000000000, 25000000000000000000);
        uint256[] memory ranks = new uint256[](3);
        ranks[1] = 2;
        ranks[2] = 1;

        Rating[] memory originalOrder =
            LibSkill.updateArenaRatings(players, ranks);

        Rating[] memory permutedPlayers = new Rating[](3);
        permutedPlayers[0] = players[2];
        permutedPlayers[1] = players[0];
        permutedPlayers[2] = players[1];
        uint256[] memory permutedRanks = new uint256[](3);
        permutedRanks[0] = ranks[2];
        permutedRanks[1] = ranks[0];
        permutedRanks[2] = ranks[1];

        Rating[] memory permutedOrder =
            LibSkill.updateArenaRatings(permutedPlayers, permutedRanks);

        _assertRatingEqual(permutedOrder[0], originalOrder[2]);
        _assertRatingEqual(permutedOrder[1], originalOrder[0]);
        _assertRatingEqual(permutedOrder[2], originalOrder[1]);
    }

    function testTeamMatchesOpenSkillHeterogeneousVector() public {
        Rating[][] memory teams = new Rating[][](2);
        teams[0] = new Rating[](2);
        teams[0][0] = _rating(20 * WAD, 10 * WAD);
        teams[0][1] = _rating(30 * WAD, 90 * WAD);
        teams[1] = new Rating[](1);
        teams[1][0] = _rating(25 * WAD, 100 * WAD);
        uint256[] memory ranks = new uint256[](2);
        ranks[1] = 1;

        Rating[][] memory next = LibSkill.updateTeamRatings(teams, ranks);

        _assertRatingApprox(
            next[0][0], 20106774862763285000, 9961951625412060000
        );
        _assertRatingApprox(
            next[0][1], 30960973764869560000, 86918081658376720000
        );
        _assertRatingApprox(
            next[1][0], 23932251372367160000, 96195162541205860000
        );

        int256 lowVarianceMovement = next[0][0].mu - teams[0][0].mu;
        int256 highVarianceMovement = next[0][1].mu - teams[0][1].mu;
        assertApproxEqAbs(
            highVarianceMovement, lowVarianceMovement * 9, REFERENCE_TOLERANCE
        );
    }

    function testProbabilityIsComplementary() public {
        Rating memory player0 = _rating(30 * WAD, 40 * WAD);
        Rating memory player1 = _rating(20 * WAD, 60 * WAD);
        int256 rankConst = LibSkill.getRankConstant(player0, player1);
        (int256 p0, int256 p1) =
            LibSkill.bradleyTerryProbability(player0, player1, rankConst);

        assertApproxEqAbs(p0 + p1, WAD, 1);
    }

    function testFuzzArenaOutputsKeepPositiveVariance(uint8 count, uint256 seed)
        public
    {
        uint256 n = bound(uint256(count), 2, 16);
        Rating[] memory players = new Rating[](n);
        uint256[] memory ranks = new uint256[](n);

        for (uint256 i; i < n; ++i) {
            uint256 value = uint256(keccak256(abi.encode(seed, i)));
            players[i] = _rating(
                int256((value % 100 + 1) * 1e18),
                int256((value % 100 + 1) * 1e18)
            );
            ranks[i] = i;
        }

        Rating[] memory next = LibSkill.updateArenaRatings(players, ranks);
        for (uint256 i; i < n; ++i) {
            assertGt(next[i].sigma2, 0);
        }
    }

    function testRevertsForInvalidArenaShapeAndVariance() public {
        uint256[] memory ranks = new uint256[](0);
        vm.expectRevert(
            abi.encodeWithSelector(LibSkill.InvalidArenaPlayerCount.selector, 0)
        );
        LibSkill.updateArenaRatings(new Rating[](0), ranks);

        Rating[] memory tooMany = new Rating[](17);
        uint256[] memory tooManyRanks = new uint256[](17);
        vm.expectRevert(
            abi.encodeWithSelector(
                LibSkill.InvalidArenaPlayerCount.selector, 17
            )
        );
        LibSkill.updateArenaRatings(tooMany, tooManyRanks);

        Rating[] memory invalidVariance = new Rating[](2);
        invalidVariance[1] = LibSkill.rating();
        uint256[] memory validRanks = new uint256[](2);
        validRanks[1] = 1;
        vm.expectRevert(LibSkill.InvalidSigma2.selector);
        LibSkill.updateArenaRatings(invalidVariance, validRanks);
    }

    function testRevertsForInvalidTeamShape() public {
        uint256[] memory ranks = new uint256[](0);
        vm.expectRevert(
            abi.encodeWithSelector(LibSkill.InvalidTeamCount.selector, 0)
        );
        LibSkill.updateTeamRatings(new Rating[][](0), ranks);

        Rating[][] memory emptyTeam = new Rating[][](2);
        emptyTeam[1] = _defaultPlayers(1);
        uint256[] memory validRanks = new uint256[](2);
        validRanks[1] = 1;
        vm.expectRevert(
            abi.encodeWithSelector(LibSkill.InvalidTeamSize.selector, 0, 0)
        );
        LibSkill.updateTeamRatings(emptyTeam, validRanks);

        Rating[] memory oversized = _defaultPlayers(9);
        vm.expectRevert(
            abi.encodeWithSelector(LibSkill.InvalidTeamSize.selector, 0, 9)
        );
        LibSkill.teamRating(oversized);

        Rating[][] memory tooManyTeams = new Rating[][](17);
        uint256[] memory tooManyRanks = new uint256[](17);
        vm.expectRevert(
            abi.encodeWithSelector(LibSkill.InvalidTeamCount.selector, 17)
        );
        LibSkill.updateTeamRatings(tooManyTeams, tooManyRanks);

        Rating[][] memory invalidVariance = new Rating[][](2);
        invalidVariance[0] = new Rating[](1);
        invalidVariance[1] = _defaultPlayers(1);
        vm.expectRevert(LibSkill.InvalidSigma2.selector);
        LibSkill.updateTeamRatings(invalidVariance, validRanks);
    }

    function testRevertsForMismatchedRanks() public {
        vm.expectRevert(bytes("LibSkill: ranks length mismatch"));
        LibSkill.updateArenaRatings(_defaultPlayers(2), new uint256[](1));

        Rating[][] memory teams = new Rating[][](2);
        teams[0] = _defaultPlayers(1);
        teams[1] = _defaultPlayers(1);
        vm.expectRevert(bytes("LibSkill: ranks length mismatch"));
        LibSkill.updateTeamRatings(teams, new uint256[](1));
    }

    function _defaultPlayers(uint256 count)
        private
        pure
        returns (Rating[] memory players)
    {
        players = new Rating[](count);
        for (uint256 i; i < count; ++i) {
            players[i] = LibSkill.rating();
        }
    }

    function _rating(int256 mu, int256 sigma2)
        private
        pure
        returns (Rating memory)
    {
        return Rating({mu: mu, sigma2: sigma2});
    }

    function _assertRatingApprox(Rating memory actual, int256 mu, int256 sigma2)
        private
    {
        assertApproxEqAbs(actual.mu, mu, REFERENCE_TOLERANCE);
        assertApproxEqAbs(actual.sigma2, sigma2, REFERENCE_TOLERANCE);
    }

    function _assertRatingEqual(Rating memory left, Rating memory right)
        private
    {
        assertEq(left.mu, right.mu);
        assertEq(left.sigma2, right.sigma2);
    }
}
