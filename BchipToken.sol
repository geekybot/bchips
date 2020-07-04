pragma solidity ^0.5.0;

import "./ERC1155.sol";
// import "./ERC1155AllowanceWrapper.sol";

/**
    @dev Mintable form of ERC1155
    Shows how easy it is to mint new items.
*/
contract BchipToken is ERC1155 {

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;

    //owner of the contract
    address public owner;
    
    // id => creators
    mapping (uint256 => address) public creators;

    // activate service provider 
    mapping (address => bool) public serviceProvider;
    
    // token exchange request mapping
    struct exchange {
        address sender;
        address reciever;
        uint256 fromTokenId;
        uint256 toTokenid;
        uint256 amount;
        bool approved;
    }

    struct mintRequest {
        address serviceProvider;
        uint tokenId; //default 0 for new token creation
        uint amount;
        bool created; //true when created
        bool status;  //false for rejected, true for to be approved or approved
        string uri;   //default "" to be pased
    }

    event Exchange(address _from, address _to, uint256 _fromid, uint256 _toid, uint256 amount, bool _approved);
    // mapping of exchange request
    
    mintRequest[] public mintRequests;
    
    mapping(address => exchange[]) public exchangeRequests;
    
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

    constructor() public {
        owner = msg.sender;
    }
    
    function submitNewTokenRequest(uint _tokenId, uint _amount, string calldata _uri) external {
        mintRequest memory mr = mintRequest(msg.sender, _tokenId, _amount, false, true, _uri);
        mintRequests.push(mr);
    }
    
    function getMintRequest(uint _index) external view returns(address, uint, bool, bool, string memory) {
        mintRequest memory mr = mintRequests[_index];
        return(mr.serviceProvider, mr.amount, mr.created, mr.status, mr.uri);
    }
    
    function getLengthMintRequests() external view returns(uint){
        return mintRequests.length;
    }

    function approveMintRequest(uint _index) external returns (uint256 _id){
        require(msg.sender == owner, "Only platform owner can create new tokens");
        mintRequest memory mr = mintRequests[_index];
        if(mr.tokenId == 0){
            _id = ++nonce;
            creators[_id] = msg.sender;
            balances[_id][mr.serviceProvider] = mr.amount;    
            serviceProvider[mr.serviceProvider] = true;
            if (bytes(mr.uri).length > 0)
                emit URI(mr.uri, _id);
        }
        else{
            _id = mr.tokenId;
            balances[_id][mr.serviceProvider] = mr.amount.add(balances[_id][mr.serviceProvider]);
            serviceProvider[mr.serviceProvider] = true;
        }
        mintRequests[_index].created = true;
        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), mr.serviceProvider, _id, mr.amount);
    }
    
    function rejectMintRequest(uint _index) external {
        require(msg.sender == owner, "Only platform owner can create new tokens");
        mintRequests[_index].created = true;
        mintRequests[_index].status = false;
    }
    

    // Creates a new token type and assings _initialSupply to minter
    function create(string calldata _uri) external returns(uint256 _id) {
        require(msg.sender == owner, "Only platform owner can create new tokens");
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
    
    function _merge(address _sender1, uint _tokenId1, address _sender2, uint _tokenId2, uint _amount, uint _mergedTokenId) internal {
        require(balances[_tokenId1][_sender1] >=_amount && balances[_tokenId2][_sender2] >=_amount, "Insufficient balance");
        balances[_tokenId1][_sender1] -= _amount;
        balances[_tokenId2][_sender2] -= _amount;
        balances[_mergedTokenId][_sender1] += _amount;
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
            msg.sender,
            _recipient,
            _fromid,
            _toid,
            _amount,
            false
        );
        exchangeRequests[_recipient].push(ec);
        //add allowance to _recipient for token exchange
        lockedTokens[msg.sender][_fromid] += _amount;
        balances[_fromid][msg.sender] -= _amount;
        emit Exchange(msg.sender, _recipient, _fromid, _toid, _amount, false);
    }
    
    function acceptExchange(uint _index) external {
        exchange storage ec = exchangeRequests[msg.sender][_index];
        lockedTokens[ec.sender][ec.fromTokenId] -= ec.amount;
        balances[ec.toTokenid][msg.sender] -= ec.amount;
        balances[ec.fromTokenId][msg.sender] += ec.amount;
        ec.approved = true;
        ec.fromTokenId = 0;
        ec.toTokenid = 0;
        ec.amount = 0;
        //set transfer/exchange succcessful
        exchangeRequests[msg.sender][_index] = ec;
        emit Exchange(ec.sender, msg.sender,  ec.fromTokenId, ec.toTokenid, ec.amount, true);
    }
    
    function getExchangeRequests(uint _index) external view returns (address, address, uint, uint, uint, bool){
        exchange memory er = exchangeRequests[msg.sender][_index];
        return(er.sender, er.reciever, er.fromTokenId, er.toTokenid, er.amount, er.approved);
    }
        
    function getLengthofExchangeRequests(address _recipient) external view returns(uint){
        return exchangeRequests[_recipient].length;
    }
    //voting campaigns
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }
    
    struct Campaign{
        address campaignCreator;
        uint256 tokenId;
        uint256 stakeAmount;
        uint256 expiry;
        bool active;
        string topic;
        bytes32 winnerName;
        uint256 voteCount;
        bool merge;
        uint256 mergeTokenId;
        uint256 senderTokenId;
        uint senderTokenAmount;
    }
    
    uint256 public campaignId = 0;
    Campaign[] public campaigns;
    mapping(uint256 => Proposal[]) public proposals;
    
    mapping(address => mapping(uint256 => bool)) public votedForCampaign;
    
    function createCampaign( uint256 _requiredTokenId, uint256 _stakeAmount, uint256 _expiry, string calldata _topic, bytes32[] calldata _proposalList, bool _mergeReq, string calldata _uri, uint _senderTokenId, uint _senderTokenAmount) external {
        require(serviceProvider[msg.sender], "Only service providers can create campaign");
        campaignId = campaignId++;
        uint256 _id = 0;
        if(_mergeReq) {
            _id = ++nonce;
            creators[_id] = owner;
            balances[_id][owner] = 0;
            
            // Transfer event with mint semantic
            emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, 0);
    
            if (bytes(_uri).length > 0)
                emit URI(_uri, _id);
        }
        balances[_senderTokenId][msg.sender] -= _senderTokenAmount;        
        Campaign memory cmp = Campaign(msg.sender, _requiredTokenId, _stakeAmount, _expiry, true, _topic, "", 0, _mergeReq, _id, _senderTokenId, _senderTokenAmount);
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
        _merge(cmp.campaignCreator, cmp.senderTokenId, msg.sender, cmp.tokenId, cmp.stakeAmount, cmp.mergeTokenId);
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
    
    function getCampaign1(uint256 _campaignId) external view returns(uint, uint256, uint256, bool, string memory, uint256){
        Campaign memory cmp = campaigns[_campaignId];
        return(cmp.tokenId, cmp.stakeAmount, cmp.expiry, cmp.active, cmp.topic, proposals[_campaignId].length);
    }
    
    function getCampaign2(uint256 _campaignId) external view returns(address, bool, uint, uint, uint){
        Campaign memory cmp = campaigns[_campaignId];
        return(cmp.campaignCreator, cmp.merge, cmp.mergeTokenId, cmp.senderTokenId, cmp.senderTokenAmount);
    }
    
    function getProposal(uint256 _campaignId, uint256 _index) public view returns(string memory){
        proposals[_campaignId][_index].name; 
    }
    
    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        emit URI(_uri, _id);
    }
}
