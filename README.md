# DshopGovernanceV1 Smart Contract

DshopGovernanceV1 is a smart contract that provides governance functionality for the decentralized shop (Dshop). Users can utilize this smart contract to create proposals within the shop and make decisions through voting.

## Features

1. **New Proposal**: Users can create proposals with various information.
2. **Voting**: Users can vote on proposals, choosing either FOR or AGAINST.
3. **Governance Result**: Proposals are determined based on the voting results, such as ACCEPTED, REJECTED, and more.

## Key Variables

- `VOTING`: State code representing the voting phase.
- `CANCELED`: State code indicating a canceled proposal.
- `RESULT_SAME`: State code indicating an equal number of FOR and AGAINST votes.
- `RESULT_FOR`: State code indicating more FOR votes than AGAINST votes.
- `RESULT_AGAINST`: State code indicating more AGAINST votes than FOR votes.
- `AVOID`: State code indicating that the minimum vote count has not been reached.

## Key Functions

- `propose`: Creates a new proposal.
- `voteFor`: Casts a FOR vote on a proposal.
- `voteAgainst`: Casts an AGAINST vote on a proposal.
- `result`: Returns the current result of the proposal.

## Governance Operation

1. Create a new proposal.
2. Conduct voting on the proposal, either casting FOR or AGAINST votes.
3. During the voting process, the proposal is not executed.
4. When voting is completed, calculate the result to determine the approval of the proposal.
5. If the proposal is approved based on the voting results, execute the proposal.

## Compiler Version Requirement

This smart contract requires Solidity version 0.5.6 or higher.

## Note

This smart contract uses Klaytn contract standards (KIP-17, KIP-7) and the SafeMath library.

---

**Usage**

To utilize the DshopGovernanceV1 smart contract, follow these steps:

1. Deploy the smart contract on the Klaytn blockchain using a compatible compiler (Solidity version 0.5.6 or higher).
2. Set the KIP7Burnable token address by calling the `setToken` function, allowing users to burn tokens for proposing.
3. Enable or disable specific NFTs for proposals using the `allownft` and `disallownft` functions, respectively.
4. Set the minimum and maximum propose periods in seconds using the `setMinProposePeriod` and `setMaxProposePeriod` functions, respectively.
5. Define the number of NFTs required for each proposal using the `setProposeNftCount` function.
6. Set the propose price in tokens using the `setProposePrice` function.
7. Determine the minimum vote count required for a proposal to be valid by calling the `setMinimumVoteCount` function.
8. Create a new proposal using the `propose` function, providing the necessary details such as title, summary, content, note, vote period, NFT address, and NFT IDs.
9. During the vote period, users can cast their votes by calling the `voteFor` or `voteAgainst` functions with the relevant NFT address and NFT IDs.
10. After the vote period ends, check the result of the proposal using the `result` function.
11. If the proposal is approved, the proposer can execute the proposal using the `execute` function.
12. If needed, the proposer can also cancel the proposal using the `cancel` function during the voting period.

**Note**

Please ensure that the smart contract's compiler version meets the requirements to avoid potential issues during deployment and execution.

Use this smart contract responsibly and be cautious when performing critical actions, such as executing proposals and setting governance parameters. Incorrect usage may lead to unintended consequences and loss of tokens or NFTs.

Always review and verify the code before deployment to ensure security and reliability.

---

**Disclaimer**

This smart contract is provided as-is without any warranty. Use it at your own risk. The developers are not liable for any loss or damage caused by the use of this smart contract.
