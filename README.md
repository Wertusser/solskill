## LibSkill

Add to your project (requires [foundry](https://book.getfoundry.sh/)):

```bash
forge install Wertusser/solskill
```

---

# Usage

```solidity
import {LibSkill, Rating} from "solskill/LibSkill.sol";

contract ExampleGame {
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
        ranks[0] = isWin ? 1 : 0;
        ranks[1] = isWin ? 0 : 1;

        Rating[] memory nextRatings = LibSkill.updateRatings(ratings, ranks);
        ratingOf[msg.sender] = nextRatings[0];
        ratingOf[opponent] = nextRatings[1];
    }
}

```
