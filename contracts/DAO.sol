//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import "hardhat/console.sol";

import "./test/NFTMarketplace.sol";

error YouAreAlreadyMember();
error NotPassed();
error NotEnoughEth();

contract DAOContract {
    uint daoMembersTotal;


    struct Proposal {
        uint voteYes;
        uint voteNo;
        uint startDate;
        uint quorum;
        uint currentDaoMembers;
        bool executed;
        bool passed;
    }

    struct Data {
        address[] targets;
        uint[] values;
        bytes[] calldatas;
        string description;
    }

    struct Member {
        uint voteWeight;
        uint memberCount;
    }


    mapping(address => Member) public daoMembers;
    mapping(uint => Proposal) public proposal;

    event newMember(address voterAddress, uint voteWeight);
    event nftBought(address nftContract, uint nftId, uint price);

    // Define the EIP712 Domain separator
    bytes32 public DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("DAOContract")),
                uint256(block.chainid),
                address(this)
            )
        );

    constructor() {
        daoMembers[msg.sender] = Member(1, 1);
        daoMembersTotal++;
    }

    function buyDaoMembership() public payable {
        require(daoMembers[msg.sender].voteWeight == 0, "You are already a member");
        require(
            msg.value >= 1 ether,
            "You need to send 1 ether to become a member"
        );
        daoMembers[msg.sender].voteWeight++;
        daoMembersTotal++;
        daoMembers[msg.sender].memberCount = daoMembersTotal * 1000;
        emit newMember(msg.sender, 1);
    }

    function createProposal(
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public {
        require(daoMembers[msg.sender].voteWeight > 0);
        require(
            targets.length == values.length &&
                targets.length == calldatas.length,
            "The length of the arrays must be the same"
        );
        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            description
        );
        proposal[proposalId] = Proposal(
            0,
            0,
            block.timestamp,
            (daoMembersTotal * 1000 * 25) / 100,
            daoMembersTotal * 1000,
            false,
            false
        );
    }

    function execute(
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public {
        require(address(this).balance >= .01 ether);
        uint256 proposalId = hashProposal(
            targets,
            values,
            calldatas,
            description
        );
        require(
            proposal[proposalId].executed == false,
            "This proposal has already been executed"
        );
        require(
            proposal[proposalId].passed == true,
            "This proposal has not passed"
        );
        require(
            proposal[proposalId].startDate + 7 days < block.timestamp,
            "This proposal has not expired"
        );
        for (uint i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(calldatas[i]);
            require(success, "Transaction failed");
        }

        proposal[proposalId].executed = true;
        daoMembers[msg.sender].voteWeight++;
        (bool sent, ) = msg.sender.call{value: .01 ether}("");
        require(sent, "Transaction failed");
        

    }

    function hashProposal(
        address[] memory targets,
        uint[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(targets, values, calldatas, description))
            );
    }

    function _voteOnProposal(uint _id, uint _vote) internal {
        require(
           proposal[_id].currentDaoMembers >= daoMembers[msg.sender].memberCount,
            "You are not allowed to vote on this!"
        );
        require(daoMembers[msg.sender].voteWeight > 0);
        require(
            proposal[_id].executed == false,
            "This proposal has already been executed"
        );
        require(
            block.timestamp < proposal[_id].startDate + 7 days,
            "This proposal has expired"
        );
        require(
            proposal[_id].voteNo + proposal[_id].voteYes < proposal[_id].quorum,
            "This proposal has already passed"
        );
        if (_vote == 1) {
            proposal[_id].voteYes += daoMembers[msg.sender].voteWeight;
        } else if (_vote == 2) {
            proposal[_id].voteNo += daoMembers[msg.sender].voteWeight;
        }
        checkIfProposalPassed(_id);
    }

    function voteOnProposal(uint _id, uint _vote) public {
        _voteOnProposal(_id, _vote);
    }

    function checkIfProposalPassed(uint _id) private {
        //fix this
        if (
            (proposal[_id].voteYes + proposal[_id].voteNo) * 1000 >=
            proposal[_id].quorum &&
            block.timestamp <= proposal[_id].startDate + 7 days &&
            proposal[_id].voteYes > proposal[_id].voteNo
        ) {
            proposal[_id].passed = true;
        }
    }

    function bytes32ToBytes(bytes32 b_) private pure returns (bytes memory) {
        return abi.encodePacked(b_);
    }

    function voteUsingSig(
        uint _id,
        uint _vote,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        require(
            proposal[_id].executed == false,
            "This proposal has already been executed"
        );
        require(
            block.timestamp < proposal[_id].startDate + 7 days,
            "This proposal has expired"
        );
        require(
            proposal[_id].voteNo + proposal[_id].voteYes < proposal[_id].quorum,
            "This proposal has already passed"
        );
        // Hash the VoteMessage with the domain separator
        bytes32 hashStruct = keccak256(
            abi.encode(keccak256("Vote(uint id,uint vote)"), _id, _vote)
        );
        // console.log("hashstruct");
        // console.logBytes(bytes32ToBytes(hashStruct));
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct)
        );
        // console.log("digest");
        // console.logBytes(bytes32ToBytes(digest));
        // console.log("domain");
        // console.logBytes(bytes32ToBytes(DOMAIN_SEPARATOR));
        address signer = ecrecover(digest, v, r, s);
        // console.log("signer", signer);
        require(daoMembers[signer].voteWeight > 0, "Invalid signature");
        _voteOnProposal(_id, _vote);
        checkIfProposalPassed(_id);
    }

         function buyNft(
        INftMarketplace market,
        address nftContract,
        uint256 nftId,
        uint256 maxPrice
    ) external {

        uint256 nftPrice = market.getPrice(nftContract, nftId);
        if (maxPrice <= nftPrice) revert NotEnoughEth();

        market.buy{value: nftPrice}(nftContract, nftId);

        emit nftBought(nftContract, nftId, nftPrice);(nftContract, nftId, nftPrice);
    }

}
