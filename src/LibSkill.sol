// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {wadPow, wadExp, wadDiv, wadMul} from "solmate/utils/SignedWadMath.sol";

function max(int256 a, int256 b) pure returns (int256) {
    return a > b ? a : b;
}

function wadSqrt(int256 a) pure returns (int256) {
    return wadPow(a, 0.5e18);
}

struct Rating {
    // mu, the mean value of the rating
    int256 mu;
    // sigma^2, the variance of the rating
    // we store squared sigma for less computation
    int256 sigma2;
}

/**
 * @title LibSkill - Skill Rating Library for multiplayer games, supports >=2 players
 * @author Wertusser
 * @dev This library is used to calculate the skill rating of players in an arena-like game.
 * This library is inspired by openskill and "A Bayesian Approximation Method for Online Ranking" paper
 * https://jmlr.org/papers/volume12/weng11a/weng11a.pdf
 */
library LibSkill {
    int256 private constant INITIAL_MU = 25000000000000000000; // 25.0 in wad
    int256 private constant INITIAL_SIGMA2 = 69444444444444444444; // (25 / 3)^2 in wad
    int256 private constant DOUBLED_BETA2 = 34722222222222222222; // 2 * (25 / 6) ^ 2 in wad
    int256 private constant LOWER_BOUND_K = 100000000000000; // 0.0001 in wad

    function rating() internal pure returns (Rating memory) {
        return Rating(INITIAL_MU, INITIAL_SIGMA2);
    }

    function ordinal(Rating memory ratings) internal pure returns (int256) {
        return ratings.mu - 3 * wadSqrt(ratings.sigma2);
    }

    function teamRating(Rating[] memory ratings)
        public
        pure
        returns (Rating memory)
    {
        int256 sumMu = 0;
        int256 sumSigma2 = 0;

        for (uint256 i = 0; i < ratings.length; i++) {
            sumMu += ratings[i].mu;
            sumSigma2 += ratings[i].sigma2;
        }

        return Rating(sumMu, sumSigma2);
    }

    function getRankConstant(Rating memory player0, Rating memory player1)
        public
        pure
        returns (int256)
    {
        return wadSqrt(player0.sigma2 + player1.sigma2 + DOUBLED_BETA2);
    }

    function bradleyTerryProbability(
        Rating memory player0,
        Rating memory player1,
        int256 rankConst
    ) public pure returns (int256 p0, int256 p1) {
        int256 exp = wadExp(wadDiv(player1.mu - player0.mu, rankConst));
        p0 = wadDiv(1e18, (1e18 + exp));
        p1 = 1e18 - p0;
    }

    function getUpdateValues(
        Rating memory player0,
        Rating memory player1,
        int256 outcome,
        int256 player0sigma
    ) internal pure returns (int256 omega, int256 delta) {
        int256 rankConst = getRankConstant(player0, player1);
        (int256 p0, int256 p1) =
            bradleyTerryProbability(player0, player1, rankConst);

        omega = wadMul(wadDiv(player0.sigma2, rankConst), (outcome - p0));

        int256 gamma = wadDiv(player0sigma, rankConst);
        delta = wadMul(wadMul(wadMul(gamma, gamma), gamma), wadMul(p0, p1));
    }

    function getOutcome(uint256 rank0, uint256 rank1)
        internal
        pure
        returns (int256)
    {
        return rank1 > rank0
            ? int256(1e18)
            : rank1 < rank0 ? int256(0) : int256(0.5e18);
    }

    function updateArenaRatings(Rating[] memory players_, uint256[] memory rank)
        public
        pure
        returns (Rating[] memory players)
    {
        uint256 n = players_.length;
        require(n == rank.length, "LibSkill: ranks length mismatch");
        players = players_;

        for (uint256 i; i < n; ++i) {
            //@dev sqrt(sigma^2) of player0 can be precomputed to save gas in nested the loop
            int256 player0sigma = wadSqrt(players_[i].sigma2);

            int256 omega = 0;
            int256 delta = 0;

            for (uint256 q; q < n; ++q) {
                if (i == q) continue;

                (int256 o, int256 d) = getUpdateValues(
                    players_[i],
                    players_[q],
                    getOutcome(rank[i], rank[q]),
                    player0sigma
                );
                omega += o;
                delta += d;
            }

            players[i].mu = players[i].mu + omega;
            players[i].sigma2 =
                wadMul(players[i].sigma2, max(1e18 - delta, LOWER_BOUND_K));
        }
    }

    function updateTeamRatings(Rating[][] memory teams_, uint256[] memory rank)
        public
        pure
        returns (Rating[][] memory teams)
    {
        uint256 n = teams_.length;
        require(n == rank.length, "LibSkill: ranks length mismatch");
        teams = teams_;

        Rating[] memory teamRatings = new Rating[](n);
        for (uint256 i = 0; i < n; ++i) {
            teamRatings[i] = teamRating(teams_[i]);
        }

        for (uint256 i; i < n; ++i) {
            Rating memory team0 = teamRatings[i];
            int256 team0sigma = wadSqrt(team0.sigma2);

            int256 omega = 0;
            int256 delta = 0;

            for (uint256 q; q < n; ++q) {
                if (i == q) continue;
                Rating memory team1 = teamRatings[q];

                (int256 o, int256 d) = getUpdateValues(
                    team0, team1, getOutcome(rank[i], rank[q]), team0sigma
                );
                omega += o;
                delta += d;
            }

            uint256 team0Size = teams_[i].length;
            for (uint256 j; j < team0Size; ++j) {
                teams[i][j].mu +=
                    wadMul(wadDiv(teams[i][j].mu, team0.mu), omega);
                teams[i][j].sigma2 = wadMul(
                    teams[i][j].sigma2,
                    max(
                        1e18
                            - wadMul(
                                wadDiv(teams[i][j].sigma2, team0.sigma2), delta
                            ),
                        LOWER_BOUND_K
                    )
                );
            }
        }
    }
}
