# DAO Project

## Setup

See [README-Setup.md](./README-Setup.md)

## Technical Spec

You are to create a DAO that accepts 1 ETH in exchange for a membership.
- Anyone can buy a membership for 1 ETH.
    - When a person becomes a member their voting power increases by 1.
    - The contributor is also marked as a member of the DAO.
    - Membership cannot be revoked.
    - You cannot by fractional membership.
    - Emit event of new member created and msg.sender address.
- Allows a member to create governance proposals.
    - Proposal will have a start and enddate.
    - Snapshot of members is taken when proposal is created.
    - 25% quorum is calculated (current members / 4)
    - Each proposal will have a creator, calldata for function, and a description. 
    - Each proposal will get hashed with all this information and added to a mapping of structs.
    - Struct will include proposal hash, totalVotes in the proposal, Quorum quota, and the yes and no votes individually, start and endate.
- Allows members to vote on proposals:
    - Members can vote over a 7 day period, right after a proposal is generated.
    - Check that proposal is under its expiration date.
    - Check that the member is on the list when snapshot was taken.
    - Votes can be either yes or no.
    - Members vote cannot be changed once it's cast.
- Proposal considered passed when:
    - When a voting period has concluded.
    - There are more Yes votes than No votes.
    - A 25% quorum requirement is met.
    - Allows any address to execute successfully passed proposals.(Meaning anyone.)
    - Reverts currently excuting proposals if any of the proposed arbitrary function calls fail.
- Function should exist for EIP-712 signatures. 
    - As well as a function for bulk signatures to vote on proposals.
- Proposal should be able to be executed by anyone, the first person to execute gets a reward.
    - This execution reward shouldn't halt the execution of the function even if it fails.
- 

## Code Coverage Report

----------------------|----------|----------|----------|----------|----------------|
File                  |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
----------------------|----------|----------|----------|----------|----------------|
 contracts/           |    65.85 |    47.83 |    81.82 |       74 |                |
  DAO.sol             |    65.85 |    47.83 |    81.82 |       74 |... 237,248,250 |
 contracts/test/      |        0 |        0 |        0 |        0 |                |
  INftMarketplace.sol |      100 |      100 |      100 |      100 |                |
  NFTMarketplace.sol  |        0 |        0 |        0 |        0 |... 45,46,49,54 |
----------------------|----------|----------|----------|----------|----------------|
All files             |    56.25 |       44 |    64.29 |    62.71 |                |
----------------------|----------|----------|----------|----------|----------------|