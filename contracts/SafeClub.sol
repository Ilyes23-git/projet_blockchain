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
    uint256 public proposalCount = 0;
    mapping(uint256 => proposal) public proposals;
    

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
    
    //Events:
   event MemberAdded(address indexed member);
   event MemberRemoved(address indexed member);
   event SetTresorier(address indexed tresorier);
   event Voted(uint256 indexed proposalId, address indexed voter, bool vote);
   event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        uint256 amount,
        address recipient,
        string description,
        uint256 deadline,
        uint256 with,
        uint256 against,
        bool validate
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event Deposit(address indexed depositor, uint256 amount);
   
   //functions
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
    function createProposal(uint256 amount,address payable recipient,string memory description,uint256 multiple) public onlyMember{
        proposal memory newProposal = proposal({
            id : proposalCount,
            proposer : msg.sender,
            amount : amount,
            recipient : recipient,
            description : description,
            deadline : block.timestamp + (multiple * 1 days),
            with : 0,
            against : 0,
            validate : false
        });
        proposals[proposalCount] = newProposal;

        proposalCount++;

        emit ProposalCreated(
            newProposal.id,
            newProposal.proposer,
            newProposal.amount,
            newProposal.recipient,
            newProposal.description,
            newProposal.deadline,
            newProposal.with,
            newProposal.against,
            newProposal.validate);
    }

    function getProposal(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        address recipient,
        uint256 amount,
        uint256 deadline,
        string memory description,
        uint256 pour,
        uint256 contre,
        bool validated) 
        {
        require(proposalId < proposalCount,"invalid index");
        proposal memory p = proposals[proposalId];
        return (proposalId,p.proposer,p.recipient,p.amount,p.deadline,p.description,p.with,p.against,p.validate);

    }

     function executeProposal(uint256 proposalId) public onlyTresorier nonReentrant{
        require(block.timestamp >= proposals[proposalId].deadline, "Vote not ended");
        require(!proposals[proposalId].validate, "Already executed");
        require(proposals[proposalId].with > proposals[proposalId].against, "Proposal rejected");
        require(tresorierBalance >= proposals[proposalId].amount, "Not enough funds");
        require(proposals[proposalId].recipient!= address(0), "Invalid recipient address");
        proposals[proposalId].validate = true;
        tresorierBalance -= proposals[proposalId].amount;
        (bool sent, ) = proposals[proposalId].recipient.call{value: proposals[proposalId].amount}("");
        require(sent, "Failed to send Ether");
        emit ProposalExecuted(proposalId);
    }

}

