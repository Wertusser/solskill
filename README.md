## LibSkill

Add to your project (requires [foundry](https://book.getfoundry.sh/)):

```bash
forge install Wertusser/solskill
```

---

# Usage

Arena updates accept 2–16 players. Team updates accept 2–16 non-empty teams,
with up to 8 players per team. Every rating must have `sigma2 > 0`.

```solidity
import {LibSkill, Rating} from "solskill/LibSkill.sol";

contract ExampleGame {
    mapping(address => Rating) public ratingOf;

    function init() public {
        ratingOf[msg.sender] = LibSkill.rating();
    }

    function fight(address opponent) public {
        require(ratingOf[opponent].mu > 0, "opponent not initialized");

        // Toy-only outcome source. Production games must resolve outcomes securely.
        bool isWin = uint256(blockhash(block.number - 1)) % 2 == 0;

        Rating[] memory ratings = new Rating[](2);
        ratings[0] = ratingOf[msg.sender];
        ratings[1] = ratingOf[opponent];

        uint256[] memory ranks = new uint256[](2);
        // Smaller rank is better: 0 is the winner.
        ranks[0] = isWin ? 0 : 1;
        ranks[1] = isWin ? 1 : 0;

        Rating[] memory nextRatings = LibSkill.updateArenaRatings(ratings, ranks);
        ratingOf[msg.sender] = nextRatings[0];
        ratingOf[opponent] = nextRatings[1];
    }
}

```
