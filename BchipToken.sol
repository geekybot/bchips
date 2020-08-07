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
    
    struct tokenInfo {
        bytes32 tokenName;
        bytes32 symbol;
    }
    //token details mapping
    
    mapping (uint256 => tokenInfo) public tokens;
    
    // id => creators
    mapping (uint256 => address) public creators;

    // activate service provider 
    mapping (address => bool) public serviceProvider;
    mapping (uint => mapping(uint => uint)) public tokenMerged; 
    
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
        bytes32 tokenName;   //default "" to be pased
        bytes32 tokenSymbol;
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
    
    function submitNewTokenRequest(uint _tokenId, uint _amount, bytes32 _tokenName, bytes32 _tokenSymbol) external {
        mintRequest memory mr = mintRequest(msg.sender, _tokenId, _amount, false, true, _tokenName, _tokenSymbol);
        mintRequests.push(mr);
    }
    
    function getMintRequest(uint _index) external view returns(address, uint, bool, bool, bytes32, bytes32, uint) {
        mintRequest memory mr = mintRequests[_index];
        return(mr.serviceProvider, mr.amount, mr.created, mr.status, mr.tokenName, mr.tokenSymbol, mr.tokenId);
    }
    
    function getLengthMintRequests() external view returns(uint){
        return mintRequests.length;
    }



    function approveMintRequest(uint _index) external returns (uint256 _id){
        require(msg.sender == owner, "Only platform owner can create new tokens");
        mintRequest memory mr = mintRequests[_index];
        if(mr.tokenId == 0){
            _id = _create(mr.tokenName, mr.tokenSymbol);
            balances[_id][mr.serviceProvider] = mr.amount;    
            serviceProvider[mr.serviceProvider] = true;
            mintRequests[_index].tokenId = _id;
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
    
    
    function tokenMergedId(uint token1, uint token2) public view returns (uint _mergedTokenId) {
        _mergedTokenId = tokenMerged[token1][token2]>0? tokenMerged[token1][token2]: tokenMerged[token2][token1];
    }

    // Creates a new token type and assings _initialSupply to minter
    function create(bytes32 _tokenName, bytes32 _tokenSymbol) external returns(uint256 _id) {
        require(msg.sender == owner, "Only platform owner can create new tokens");
        _id = _create(_tokenName, _tokenSymbol);
    }
    
    function _create(bytes32 _tokenName, bytes32 _tokenSymbol) internal returns(uint256 _id) {
        _id = ++nonce;
        creators[_id] = msg.sender;
        balances[_id][msg.sender] = 0;
        tokenInfo memory ti = tokenInfo(_tokenName, _tokenSymbol);
        tokens[_id] = ti;
        // Transfer event with mint semantic
        emit TransferSingle(msg.sender, address(0x0), msg.sender, _id, 0);

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
    
    
    function safeBatchAward(address _from, address[] calldata _to, uint256 _id, uint256[] calldata _values) external {
        // MUST Throw on errors
        require(_to.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");
        uint256 id = _id;
        for (uint256 i = 0; i < _to.length; ++i) {
            require(_to[i] != address(0x0), "destination address must be non-zero.");
            address receiver = _to[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][receiver]   = value.add(balances[id][receiver]);
        }
    }
    
    function _merge(address _sender1, uint _tokenId1, address _sender2, uint _tokenId2, uint _amount, uint _mergedTokenId) internal {
        require( serviceProvider[_sender1], "Only service provider can merge tokens");
        require(balances[_tokenId1][_sender1] >=_amount && balances[_tokenId2][_sender2] >=_amount, "Insufficient balance");
        balances[_tokenId1][_sender1] -= _amount;
        balances[_tokenId2][_sender2] -= _amount;
        balances[_mergedTokenId][_sender2] += _amount;
    }
    
    
    // internal function to mint token/ award token to user on voting campaign
    function _awardToken(address _minter, address _recipient, uint _tokenId, uint _amount) internal {
        require(serviceProvider[_minter], "Minter is not a service provider");
         balances[_tokenId][_recipient] = _amount.add(balances[_tokenId][_recipient]);
        // Emit the Transfer/Mint event.
        // the 0x0 source address implies a mint
        // It will also provide the circulating supply info.
        emit TransferSingle(_minter, address(0x0), _recipient, _tokenId, _amount);

        if (_recipient.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _recipient, _tokenId, _amount, '');
        }
    }
    
    // internal function to exchange token between serviceProvider and user on voting on a campiagn
    function _exchangeToken(address _provider, uint _providerTokenId, address _recipient, uint _tokenId, uint _amount) internal {
        require(serviceProvider[_provider], "Minter is not a service provider");
        require(balances[_tokenId][_recipient] >= _amount, "Receipient doesn't have enought balance to exchange");
        require(balances[_providerTokenId][_provider] >= _amount, "Service Provider doesn't have enought balance to exchange");
        // update Receipient balance accordingly
        balances[_tokenId][_recipient] = _amount.sub(balances[_tokenId][_recipient]);
        balances[_providerTokenId][_recipient] = _amount.add(balances[_providerTokenId][_recipient]);
        // update service provider balance accordingly
        balances[_providerTokenId][_provider] = _amount.add(balances[_providerTokenId][_provider]);
        balances[_tokenId][_provider] = _amount.sub(balances[_tokenId][_provider]);
        
        // It will also provide the circulating supply info.
        emit TransferSingle(_provider, address(0x0), _recipient, _tokenId, _amount);

        if (_recipient.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _recipient, _tokenId, _amount, '');
        }
    }
    
    
    
    // function createMergeCampaign(){
        
    // }
    
    function burn(uint256[] calldata _id, uint256[] calldata _amounts) external {
        require(serviceProvider[msg.sender], "Only service provider can burn redeemed tokens");
        for (uint256 i = 0; i < _id.length; ++i) {
            balances[_id[i]][msg.sender] -= _amounts[i];
            //Burn all token of a service provider
            //amount zero signifies token burned
            emit TransferSingle(msg.sender, address(0x0), address(0x0), _id[0], _amounts[i]);
        }
    }
    
    function redeem(uint _tokenId, uint _amount, address _serviceProvider) external {
        require(balances[_tokenId][msg.sender]>= _amount, "Insufficient balance to redeem");
        balances[_tokenId][msg.sender] -= _amount;
        // if from addres is address of zero token is burned to serviceprovider
        emit TransferSingle(msg.sender, address(0x0), _serviceProvider, _tokenId, _amount);
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
        balances[ec.fromTokenId][ec.reciever] += ec.amount;
        ec.approved = true;
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
        // 1 = merge, 2= award, 3 = exchange
        uint256 campaignType;
        uint256 mergeTokenId;
        uint256 senderTokenId;
        uint senderTokenAmount;
    }
    
    Campaign[] public campaigns;
    mapping(uint256 => Proposal[]) public proposals;
    
    mapping(address => mapping(uint256 => bool)) public votedForCampaign;
    
    function createCampaign( uint8 _requiredTokenId, uint256 _stakeAmount, uint256 _expiry, string calldata _topic, bytes32[] calldata _proposalList, uint _campaignType, bytes32[] calldata _tokenDetails,  uint8 _senderTokenId, uint _senderTokenAmount) external {
        require(serviceProvider[msg.sender], "Only service providers can create campaign");
        uint256 _id;
        if(_campaignType == 1){
            if(tokenMerged[_requiredTokenId][_senderTokenId] == 0 || tokenMerged[_senderTokenId][_requiredTokenId] == 0 ){
                _id = _create(_tokenDetails[0], _tokenDetails[1]);
                tokenMerged[_requiredTokenId][_senderTokenId] = _id;
            }
            else{
                _id = tokenMerged[_requiredTokenId][_senderTokenId]>0? tokenMerged[_requiredTokenId][_senderTokenId]: tokenMerged[_senderTokenId][_requiredTokenId];
            }
        }
        Campaign memory cmp = Campaign(msg.sender, _requiredTokenId, _stakeAmount, _expiry, true, _topic, "", 0, _campaignType, _id, _senderTokenId, _senderTokenAmount);
        campaigns.push(cmp);
        uint cmpId = campaigns.length-1;
        for (uint i = 0; i < _proposalList.length; i++) {
            proposals[cmpId].push(Proposal({
                name: _proposalList[i],
                voteCount: 0
            }));
        }
    }
    
    function vote(uint256 _campaignId, uint256 _proposalId) external {
        Campaign memory cmp = campaigns[_campaignId];
        require(balances[cmp.tokenId][msg.sender] > cmp.stakeAmount, "Insufficient token balance to vote");
        require(now < cmp.expiry, "Campaign deadline expired");
        require(cmp.active, "Campaign closed");
        require(!votedForCampaign[msg.sender][_campaignId], "User already voted for this");
        votedForCampaign[msg.sender][_campaignId] = true;
        proposals[_campaignId][_proposalId].voteCount += 1;
        if(cmp.campaignType == 1){
            _merge( msg.sender, cmp.tokenId, cmp.campaignCreator, cmp.senderTokenId, cmp.stakeAmount, cmp.mergeTokenId);
        }
        else if(cmp.campaignType == 2){
            _awardToken(cmp.campaignCreator, msg.sender, cmp.senderTokenId, cmp.senderTokenAmount);
        }
        else if(cmp.campaignType == 3){
            _exchangeToken(cmp.campaignCreator, cmp.tokenId, msg.sender, cmp.senderTokenId, cmp.senderTokenAmount);
        }
    }
    
    function winningProposal(uint256 _campaignId) external returns (bytes32) {
        require(campaigns[_campaignId].campaignCreator == msg.sender, "Only creator of this campaign close the campaign and declare the winner");
        // require(campaigns[_campaignId].expiry<now, "You can't declare the winner yet, campign is still running");
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
        campaigns[_campaignId].active = false;
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
    
    function getCampaign2(uint256 _campaignId) external view returns(address, uint, uint, uint, uint){
        Campaign memory cmp = campaigns[_campaignId];
        return(cmp.campaignCreator, cmp.campaignType, cmp.mergeTokenId, cmp.senderTokenId, cmp.senderTokenAmount);
    }
    
    //Merge campaign
    struct MergeCampaign{
        address campaignCreator;
        uint baseTokenId;
        uint256 baseTokenAmount;
        uint256 spenderTokenId;
        uint mergeTokenId;
        uint expiry;
    }
    
    MergeCampaign[] public mergeCampaigns;
    
    function createMergeCampaign(uint _baseTokenId, uint _baseTokenAmount, uint _spenderTokenId, bytes32[] calldata _tokenDetails, uint _expiry) external {
        require(serviceProvider[msg.sender], "Only service providers can create merge campaign");
        require(balances[_baseTokenId][msg.sender] >= _baseTokenAmount, "Service provider doesn't have enough balance to start the campaign");
        require(_baseTokenId<nonce && _spenderTokenId<nonce, "Tokens doesn't exist");
        require(now < _expiry, "Can't set a past date as expiration date");
        uint256 _id;
        if(tokenMerged[_baseTokenId][_spenderTokenId] == 0 || tokenMerged[_spenderTokenId][_baseTokenId] == 0 ){
            _id = _create(_tokenDetails[0], _tokenDetails[1]);
            tokenMerged[_baseTokenId][_spenderTokenId] = _id;
        }
        else{
            _id = tokenMerged[_baseTokenId][_spenderTokenId]>0? tokenMerged[_baseTokenId][_spenderTokenId]: tokenMerged[_spenderTokenId][_baseTokenId];
        }
        MergeCampaign memory mcp = MergeCampaign(msg.sender, _baseTokenId, _baseTokenAmount, _spenderTokenId, _id, _expiry);
        mergeCampaigns.push(mcp);
    }
    
    function merge( uint _tokenId1, address _sender2, uint _tokenId2, uint _amount, bytes32 tokenName, bytes32 tokenSymbol) external {
        require(balances[_tokenId1][msg.sender] > _amount, "Insufficient token balance to merge");
        require(balances[_tokenId2][_sender2] > _amount, "Insufficient token balance to merge");
        uint256 _mergedTokenId = tokenMerged[_tokenId1][_tokenId2]>0? tokenMerged[_tokenId1][_tokenId2]: tokenMerged[_tokenId2][_tokenId1];
        if (_mergedTokenId == 0){
           _mergedTokenId =  _create(tokenName, tokenSymbol);
        }
        _merge(msg.sender, _tokenId1, _sender2, _tokenId2, _amount, _mergedTokenId);
    }
    
    function mergeCampaignLength() external view returns(uint mergeLength){
        mergeLength = mergeCampaigns.length;
    }
    
    function setURI(string calldata _uri, uint256 _id) external creatorOnly(_id) {
        emit URI(_uri, _id);
    }
}
