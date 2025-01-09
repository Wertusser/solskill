// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library LibSkill {
    int256 constant BETA = 400;
    int256 constant LEARNING_RATE = 400;

    struct Rating {
        int256 mu; // mu, the mean value of the rating
        int256 sigma2; // sigma^2, the variance of the rating
    }

    function teamRating(Rating[] memory ratings) public pure returns (Rating memory) {
        int256 sumMu = 0;
        int256 sumSigma2 = 0;

        for (uint256 i = 0; i < ratings.length; i++) {
            sumMu += ratings[i].mu;
            sumSigma2 += ratings[i].sigma2;
        }

        return Rating(sumMu, sumSigma2);
    }

    function getConstant(Rating memory team0, Rating memory team1) public pure returns (int256) {
        return sqrt(team0.sigma2 + team1.sigma2 + 2 * BETA * BETA);
    }

    function probability(Rating memory team0, Rating memory team1, int256 constVal) public pure returns (int256) {
        int256 exp0 = exp(team0.mu / constVal);
        int256 exp1 = exp(team1.mu / constVal);

        return exp0 / (exp0 + exp1);
    }

    function foo(Rating memory team0, Rating memory team1, int256 outcome) public pure returns (int256, int256) {
        int256 constVal = getConstant(team0, team1);
        int256 p0 = probability(team0, team1, constVal);
        int256 p1 = probability(team1, team0, constVal);

        int256 sigma = team0.sigma2 / constVal * (outcome - p0);
        int256 etha = LEARNING_RATE * team0.sigma2 / (constVal * constVal) * (p0 * p1);

        return (sigma, etha);
    }

    function teamFoo(Rating[] memory teams, uint256 teamComparedIndex, int256 outcome)
        public
        pure
        returns (int256 omega, int256 delta)
    {
        uint256 n = teams.length;

        for (uint256 q = 0; q < n; q++) {
            if (teamComparedIndex == q) continue;

            (int256 sigma, int256 etha) = teamSkill(teams[teamComparedIndex], teams[q], outcome);
            omega += sigma;
            delta += etha;
        }
    }

    function teamSkill(Rating[] memory teams, int256 outcome) public pure returns (int256) {
        uint256 n = teams.length;
        for (uint256 i = 0; i < n; i++) {
            int256 omega = 0;
            int256 delta = 0;

            for (uint256 q = 0; q < n; q++) {
                if (i == q) continue;

                (int256 sigma, int256 etha) = teamSkill(teams[i], teams[q], outcome);
                omega += sigma;
                delta += etha;
            }
        }
    }
}
