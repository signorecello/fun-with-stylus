# Ballot on Arbitrum Stylus

A commit-reveal voting contract on Stylus. An admin registers 5 voters, who commit hashed votes for candidate A or B, then reveal. The admin goes and advances the multiple phases, and tallies the results.

Each voter is supposed to know a secret (salt) that they use to hash their vote before committing. Ofc in real life this wouldn't be a great ballot, but that's not the point here anyway

## Quick start

```bash
make -C ballot setup   # deploy, register voters, advance to commit phase
make -C ballot demo    # run full commit-reveal-tally flow
```
