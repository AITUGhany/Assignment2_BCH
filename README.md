Building the project:
forge build

Run all tests:
forge test

Detailed Gas Report:
forge test --gas-report

Deep debugging mode:
forge test -vvvv

-----------------------------------
Fuzz Testing:
forge test --match-test testFuzz_Swap

Invariant Testing:
forge test --match-test test_Invariant_K_Value

Fork Testing Against Mainnet:
forge test --match-test test_Fork_USDC_Supply

Lending Protocol:
forge test --match-test test_Lending_InterestAccrual

