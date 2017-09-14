pragma solidity 0.4.16;



contract TableCoin {

    uint256 public crowdFundReserveAmount;

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    mapping (address => uint256) public balances;

    function TableCoin() {
        balances[msg.sender] = crowdFundReserveAmount;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount);
        return true;
    }
}
contract Owned {

    address public owner; // temporary address

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner)
            revert();
        _; // function code inserted here
    }


    function transferOwnership(address _newOwner) onlyOwner returns (bool success) {
        if (msg.sender != owner)
            revert();
        owner = _newOwner;
        return true;
        
    }

}

contract SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function safeToAdd(uint a, uint b) internal returns (bool) {
        return (a + b >= a);
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        if (!safeToAdd(a, b)) 
            revert();
        return a + b;
    }

    function safeToSubtract(uint a, uint b) internal returns (bool) {
        return (b <= a);
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        if (!safeToSubtract(a, b)) 
            revert();
        return a - b;
    } 

}


contract CrowdFund is SafeMath, Owned {

    uint256     public tokenCostInWei = 3000000000000000;
    uint256     public fundingGoalInEther;
    uint256     public crowdFundReserve = 0;
    uint256     public tokensBought;
    uint256     public presaleDeadline;
    // start of presale block #
    uint256     public startOfPresaleInBlockNumber;
    // start of presale in minutes
    uint256     public startOfPresaleInMinutes;
    address     public tokenContractAddress;
    bool        public crowdFundFrozen;
    TableCoin   public tokenReward;

    event LaunchCrowdFund(bool launched);
    event FundTransfer(address _backer, uint256 _amount, bool didContribute);
    
    mapping (address => uint256) public balances;

    modifier onlyAfterReserveSet() {
        require(crowdFundReserve > 0);
        _;
    }

    modifier onlyBeforeCrowdFundStart() {
        require(crowdFundFrozen);
        _;
    }

    function CrowdFund(address _tokenContractAddress) {
        tokenContractAddress = _tokenContractAddress;
        tokenReward = TableCoin(tokenContractAddress);
        crowdFundFrozen = true;
    }

    function startCrowdFund() onlyOwner onlyAfterReserveSet public returns (bool success) {
        startOfPresaleInBlockNumber = now;
        startOfPresaleInMinutes = now * 1 minutes;
        crowdFundFrozen = false;
        return true;
    }

    function setCrowdFundReserve(uint256 _amount) onlyOwner onlyBeforeCrowdFundStart public returns (bool success) {
        crowdFundReserve = _amount;
    }

    function() payable {
        require(!crowdFundFrozen);
        require(msg.value > 0 && msg.value >= tokenCostInWei);
        uint256 _amountTBCReceive = div(msg.value, tokenCostInWei);
        uint256 amountTBCReceive = mul(_amountTBCReceive, 1 ether);
        balances[msg.sender] = safeAdd(balances[msg.sender], amountTBCReceive);
        if (!tokenReward.transfer(msg.sender, amountTBCReceive)) {
            revert();
        } else {
            FundTransfer(msg.sender, amountTBCReceive, true);
        }
    }
}