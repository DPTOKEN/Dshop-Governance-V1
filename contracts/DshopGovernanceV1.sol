pragma solidity ^0.5.6;

import "./klaytn-contracts/token/KIP17/IKIP17Enumerable.sol";
import "./klaytn-contracts/token/KIP7/KIP7Burnable.sol";
import "./klaytn-contracts/ownership/Ownable.sol";
import "./klaytn-contracts/math/SafeMath.sol";
import "./interfaces/IDshopGovernanceV1.sol";

contract DshopGovernanceV1 is Ownable, IDshopGovernanceV1 {
    using SafeMath for uint256;

    uint8 public constant VOTING = 0;
    uint8 public constant CANCELED = 1;
    uint8 public constant RESULT_SAME = 2;
    uint8 public constant RESULT_FOR = 3;
    uint8 public constant RESULT_AGAINST = 4;
    uint8 public constant AVOID = 5;

    KIP7Burnable public token;

    mapping(address => bool) public nftAllowed;
    uint256 public minProposePeriod = 86400;
    uint256 public maxProposePeriod = 604800;
    uint256 public proposeNftCount = 0;

    uint256 public proposePrice = 800 * 1e18;
    uint256 public minimumVoteCount = 3000;

    struct Proposal {
        address proposer;
        string title;
        string summary;
        string content;
        string note;
        uint256 blockNumber;
        address proposenft;
        uint256 votePeriod;
        bool canceled;
        bool executed;
    }
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => uint256[])) public proposenft;
    mapping(uint256 => uint256) public forVotes;
    mapping(uint256 => uint256) public againstVotes;
    mapping(uint256 => mapping(address => mapping(uint256 => bool)))
        public nftVoted;

    function setToken(KIP7Burnable _token) external onlyOwner {
        token = _token;
    }

    function allownft(address nft) external onlyOwner {
        nftAllowed[nft] = true;
    }

    function disallownft(address nft) external onlyOwner {
        nftAllowed[nft] = false;
    }

    function setMinProposePeriod(uint256 period) external onlyOwner {
        minProposePeriod = period;
    }

    function setMaxProposePeriod(uint256 period) external onlyOwner {
        maxProposePeriod = period;
    }

    function setProposeNftCount(uint256 count) external onlyOwner {
        proposeNftCount = count;
    }

    function setProposePrice(uint256 price) external onlyOwner {
        proposePrice = price;
    }

    function setMinimumVoteCount(uint256 voteCount) external onlyOwner {
        minimumVoteCount = voteCount;
    }

    function propose(
        string calldata title,
        string calldata summary,
        string calldata content,
        string calldata note,
        uint256 votePeriod,
        address _nft,
        uint256[] calldata nftIds
    ) external returns (uint256 proposalId) {
        require(nftAllowed[_nft] == true);
        require(nftIds.length == proposeNftCount);
        require(
            minProposePeriod <= votePeriod && votePeriod <= maxProposePeriod
        );

        proposalId = proposals.length;
        proposals.push(
            Proposal({
                proposer: msg.sender,
                title: title,
                summary: summary,
                content: content,
                note: note,
                blockNumber: block.number,
                proposenft: _nft,
                votePeriod: votePeriod,
                canceled: false,
                executed: false
            })
        );

        uint256[] storage proposed = proposenft[proposalId][_nft];
        IKIP17Enumerable nft = IKIP17Enumerable(_nft);

        for (uint256 index = 0; index < proposeNftCount; index = index.add(1)) {
            uint256 id = nftIds[index];
            require(nft.ownerOf(id) == msg.sender);
            nft.transferFrom(msg.sender, address(this), id);
            proposed.push(id);
        }

        token.burnFrom(msg.sender, proposePrice);

        emit Propose(proposalId, msg.sender, _nft, nftIds);
    }

    function proposalCount() external view returns (uint256) {
        return proposals.length;
    }

    modifier onlyVoting(uint256 proposalId) {
        Proposal memory proposal = proposals[proposalId];
        require(
            proposal.canceled != true &&
                proposal.executed != true &&
                proposal.blockNumber.add(proposal.votePeriod) >= block.number
        );
        _;
    }

    function voteNft(
        uint256 proposalId,
        address _nft,
        uint256[] memory nftIds
    ) internal {
        require(nftAllowed[_nft] == true);

        mapping(uint256 => bool) storage voted = nftVoted[proposalId][_nft];
        IKIP17Enumerable nft = IKIP17Enumerable(_nft);

        uint256 length = nftIds.length;
        for (uint256 index = 0; index < length; index = index.add(1)) {
            uint256 id = nftIds[index];
            require(nft.ownerOf(id) == msg.sender && voted[id] != true);
            voted[id] = true;
        }
    }

    function voteFor(
        uint256 proposalId,
        address nft,
        uint256[] calldata nftIds
    ) external onlyVoting(proposalId) {
        voteNft(proposalId, nft, nftIds);
        forVotes[proposalId] = forVotes[proposalId].add(nftIds.length);
        emit VoteFor(proposalId, msg.sender, nft, nftIds);
    }

    function voteAgainst(
        uint256 proposalId,
        address nft,
        uint256[] calldata nftIds
    ) external onlyVoting(proposalId) {
        voteNft(proposalId, nft, nftIds);
        againstVotes[proposalId] = againstVotes[proposalId].add(nftIds.length);
        emit VoteAgainst(proposalId, msg.sender, nft, nftIds);
    }

    modifier onlyProposer(uint256 proposalId) {
        require(proposals[proposalId].proposer == msg.sender);
        _;
    }

    function getBacknft(uint256 proposalId) external onlyProposer(proposalId) {
        require(result(proposalId) != VOTING);

        Proposal memory proposal = proposals[proposalId];
        uint256[] memory proposed = proposenft[proposalId][proposal.proposenft];
        IKIP17Enumerable nft = IKIP17Enumerable(proposal.proposenft);
        uint256 length = proposed.length;

        for (uint256 index = 0; index < length; index = index.add(1)) {
            nft.transferFrom(address(this), proposal.proposer, proposed[index]);
        }

        delete proposenft[proposalId][proposal.proposenft];
    }

    function nftBacked(uint256 proposalId) external view returns (bool) {
        Proposal memory proposal = proposals[proposalId];
        return proposenft[proposalId][proposal.proposenft].length == 0;
    }

    function cancel(uint256 proposalId) external onlyProposer(proposalId) {
        Proposal memory proposal = proposals[proposalId];
        require(proposal.blockNumber.add(proposal.votePeriod) >= block.number);
        proposals[proposalId].canceled = true;
        emit Cancel(proposalId);
    }

    function execute(uint256 proposalId) external onlyProposer(proposalId) {
        require(result(proposalId) == RESULT_FOR);
        proposals[proposalId].executed = true;
        emit Execute(proposalId);
    }

    function result(uint256 proposalId) public view returns (uint8) {
        Proposal memory proposal = proposals[proposalId];
        uint256 _for = forVotes[proposalId];
        uint256 _against = againstVotes[proposalId];
        if (proposal.canceled == true) {
            return CANCELED;
        } else if (
            proposal.blockNumber.add(proposal.votePeriod) >= block.number
        ) {
            return VOTING;
        } else if (_for.add(_against) < minimumVoteCount) {
            return AVOID;
        } else if (_for == _against) {
            return RESULT_SAME;
        } else if (_for > _against) {
            return RESULT_FOR;
        } else {
            return RESULT_AGAINST;
        }
    }
}
