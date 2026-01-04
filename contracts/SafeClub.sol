// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SafeClub{
    address private immutable owner;
    address public tresorier;
    uint256 public tresorierBalance;
    address[] public members;
    mapping (address => bool) public isMember;
    mapping (address => bool) public hasVoted;
    struct proposal{
        uint256 id;
        address proposer;
        uint256 amount;
        address payable recipient;
        string description;
        uint256 deadline;
        uint256 with;
        uint256 against;
        bool validate;
    }
    

    // Modifiers:
    modifier onlyOwner() {
        require(msg.sender == owner,"only owner have permission !");
        _;
    }

    modifier onlyTresorier() {
        require(msg.sender == tresorier,"only tresoeier have permission !");
        _;
    }

    modifier onlyMember() {
        bool found = false;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                found = true;
                break;
            }
        }
        require(found, "Only member");
        _;
    }

   event MemberAdded(address indexed member);
   event MemberRemoved(address indexed member);
   event SetTresorier(address indexed tresorier);
   event Voted(uint256 indexed proposalId, address indexed voter, bool vote);
   
   
    function setTresorier(address Tresorier) public onlyOwner{
        require(Tresorier != address(0), "Invalid address: Zero address not allowed");
        tresorier = Tresorier;
        emit SetTresorier(Tresorier);
    }
    function addMember(address Member) public onlyOwner {
        require(!isMember[Member], "Member already exists");
        require(Member != address(0), "Invalid address: Zero address not allowed");
        members.push(Member);
        isMember[Member] = true;
        emit MemberAdded(Member);
    }
    function removeMember(address member) public onlyOwner {
        require(isMember[member], "member does not exist");
        uint256 index = 0;
        uint256 len = members.length;
        for (uint256 i = 0; i < len; i++) {
            if (members[i] == member) {
                index = i;
                break;
            }
        }
        members[index] = members[members.length - 1];
        members.pop();
        isMember[member] = false;
        emit MemberRemoved(member);
    }

   function voter(uint256 _proposalId, bool _vote) public onlyMember {
        require(block.number <= proposals[_proposalId].deadline, "Vote ended");
        require(!hasVoted[msg.sender], "Already voted");

        if (_vote) {
            proposals[_proposalId].with++;
        } else {
            proposals[_proposalId].against++;
        }

        hasVoted[msg.sender] = true;
        emit Voted(_proposalId,msg.sender, _vote);
    }

}

