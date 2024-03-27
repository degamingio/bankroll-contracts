# Properties

- Valid States
- State Transitions
- Variable Transitions
- High-Level Properties
- Unit Tests

## Bankroll

| Property | Description                                 | Category     | Added | Tested |
| -------- | ------------------------------------------- | ------------ | ----- | ------ |
| BKR-01   | Shares may never be minted for free         | High Level   | ✅    | ❌     |
| BKR-02   | Tokens may never be withdrawn for free      | High Level   | ✅    | ❌     |
| BKR-03   | Liquidity to shares always gte total supply | Valid States | ✅    | ❌     |
| BKR-04   | Balance always gte GGR                      | Valid States | ✅    | ❌     |
| BKR-05   | GGR is equal to sum of ggrOf                | Valid States | ✅    | ❌     |
| BKR-06   |                                             | High Level   | ❌    |        |
| BKR-07   |                                             | High Level   | ❌    |        |
