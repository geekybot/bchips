
pragma solidity ^0.5.0;

import "./ERC1155.sol";
// import "./ERC1155AllowanceWrapper.sol";

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items.
*/
contract BchipToken is ERC1155 {

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    // id => creators
    mapping (uint256 => address) public creators;

    // activate service provider 
    mapping (address => bool) public serviceProvider;
    
    // token exchange request mapping
    struct exchange {
        uint256 fromTokenId;
        uint256 toTokenid;
        uint256 amount;
        bool approved;
    }

    event Exchange(address _from, address _to, uint256 _fromid, uint256 _toid, uint256 amount, bool _approved);
    // mapping of exchange request
    mapping(address => mapping(address => exchange)) public exchangeRequest;
    
    mapping(address => mapping(uint256 => uint256)) public lockedTokens;

    // A nonce to ensure we have a unique id each time we mint.
    uint256 public nonce;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender);
        _;
    }

   
    function supportsInterface(bytes4 _interfaceId)
    public
    view
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }

    // Creates a new token type and assings _initialSupply to minter
    function create(string calldata _uri) external returns(uint256 _id) {
        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = 0;
        
        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, 0);

        if (bytes(_uri).length > 0)
            emit URI(_uri, _id);
    }

    // Batch mint tokens. Assign directly to _to[].
    function mint(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external creatorOnly(_id) {

        for (uint256 i = 0; i < _to.length; ++i) {

            address to = _to[i];
            uint256 quantity = _quantities[i];

            // Grant the items to the caller
            balances[_id][to] = quantity.add(balances[_id][to]);
            serviceProvider[to] = true;
            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), to, _id, quantity);

            if (to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, to, _id, quantity, '');
            }
        }
    }
    
    function burn(uint256[] calldata _id, uint256[] calldata _amounts) external {
        require(serviceProvider[msg.sender], "Only service provider can burn redeemed tokens");
        for (uint256 i = 0; i < _id.length; ++i) {
            balances[_id[i]][msg.sender] -= _amounts[i];
            //Burn all token of a service provider
            //amount zero signifies token burned
            emit TransferSingle(msg.sender, address(0x0), address(0x0), _id[0], _amounts[i]);
        }
    }
    
    function tokenExchangeRequest( uint256 _fromid, uint256 _toid, uint256 _amount, address _recipient) external {
        require(_recipient != address(0x0), "Can't request exchange to a null address");
        require(balances[_fromid][msg.sender] >= _amount && balances[_toid][_recipient] >= _amount, "Insufficient amount to exchange");
        exchange memory ec =  exchange(
            _fromid,
            _toid,
            _amount,
            false
        );
        exchangeRequest[msg.sender][_recipient] = ec;
        //add allowance to _recipient for token exchange
        lockedTokens[msg.sender][_fromid] += _amount;
        balances[_fromid][msg.sender] -= _amount;
        emit Exchange(msg.sender, _recipient, _fromid, _toid, _amount, false);
    }
    
    function acceptExchange(address _sender) external {
        exchange storage ec = exchangeRequest[_sender][msg.sender];
        lockedTokens[_sender][ec.fromTokenId] -= ec.amount;
        balances[ec.toTokenid][msg.sender] -= ec.amount;
        balances[ec.fromTokenId][msg.sender] += ec.amount;
        ec.approved = true;
        ec.fromTokenId = 0;
        ec.toTokenid = 0;
        ec.amount = 0;
        //set transfer/exchange succcessful
        exchangeRequest[_sender][msg.sender] = ec;
        emit Exchange(_sender, msg.sender,  ec.fromTokenId, ec.toTokenid, ec.amount, true);
    }
        
    //voting campaigns
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }
    
    struct Campaign{
        uint256 tokenId;
        uint256 stakeAmount;
        uint256 expiry;
        bool active;
        string topic;
        bytes32 winnerName;
        uint256 voteCount;
    }
    
    uint256 public campaignId = 0;
    Campaign[] public campaigns;
    mapping(uint256 => Proposal[]) public proposals;
    
    mapping(address => mapping(uint256 => bool)) public votedForCampaign;
    
    function createCampaign(uint256 _requiredTokenId, uint256 _stakeAmount, uint256 _expiry, string calldata _topic, bytes32[] calldata _proposalList) external {
        require(serviceProvider[msg.sender], "Only service providers can create campaign");
        campaignId = campaignId++;
        Campaign memory cmp = Campaign(_requiredTokenId, _stakeAmount, _expiry, true, _topic, "", 0);
        campaigns.push(cmp);
        for (uint i = 0; i < _proposalList.length; i++) {
            proposals[campaignId].push(Proposal({
                name: _proposalList[i],
                voteCount: 0
            }));
        }
    }
    
    function vote(uint256 _campaignId, uint256 _proposalId) external {
        Campaign memory cmp = campaigns[_campaignId];
        require(balances[cmp.tokenId][msg.sender] > cmp.stakeAmount, "Insufficient token balance to vote");
        require(now < cmp.expiry, "Campaign deadline expired");
        require(!votedForCampaign[msg.sender][_campaignId], "User already voted for this");
        balances[cmp.tokenId][msg.sender] -= cmp.stakeAmount;
        votedForCampaign[msg.sender][_campaignId] = true;
        proposals[_campaignId][_proposalId].voteCount += 1;
    }
    
    function winningProposal(uint256 _campaignId) external returns (bytes32) {
        require(serviceProvider[msg.sender], "Only service providers can find a winning proposal");
        uint winningVoteCount = 0;
        bytes32 winnerName= "";
        for (uint p = 0; p < proposals[_campaignId].length; p++) {
            Proposal memory cp = proposals[_campaignId][p];
            if (cp.voteCount >= winningVoteCount) {
                winningVoteCount = cp.voteCount;
                winnerName = cp.name;
            }
        }
        campaigns[_campaignId].voteCount = winningVoteCount;
        campaigns[_campaignId].winnerName = winnerName;
        return winnerName;
    }
    
    function getWinnerOfCampaign(uint256 _campaignId) external view returns( string memory, bytes32, uint256){
        Campaign memory cmp = campaigns[_campaignId];
        return(cmp.topic, cmp.winnerName, cmp.voteCount);
    }
    
    function getProposalLength(uint256 _campaignId) external view returns( uint256 proposalLength){
        return proposals[_campaignId].length;
    }

    function getCampaignLength() external view returns(uint256 campaignLength) {
        return campaigns.length;
    }
    
    function gateCampaign(uint256 _campaignId) external view returns(uint256, uint256, uint256, bool, string memory, uint256){
        Campaign memory cmp = campaigns[_campaignId];
        return(cmp.tokenId, cmp.stakeAmount, cmp.expiry, cmp.active, cmp.topic, proposals[_campaignId].length);
    }
    
    function getProposal(uint256 _campaignId, uint256 _index) public view returns(string memory){
        proposals[_campaignId][_index].name; 
    }
    
    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        emit URI(_uri, _id);
    }
}
