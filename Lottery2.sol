pragma solidity ^0.4.17;

contract Lottery {
 address public manager;
 address[] public players;

//  functions for ticketing system
mapping (address => uint26) public winnings; 

 address[] public tickets;
 uint public ticketCount = 0;
 uint public ticketPrice = 0.1; 
 uint256 public randomNum = 0;
 address public latestWinner; 
 
 // constructor : as soon as creating contract, it has been also called
 function Lottery() public {
    // msg is a global function
    manager = msg.sender; // Person who create Contract
 }

 // sending Eth to enter loggery: payable function type
 function enter() public payable{
    require(msg.value >= ticketPrice ether); // some requirements satisfied, then go through next
    players.push(msg.sender);
    for (int i = 0; i < ticketCount; i++){
        tickets.push(msg.sender);
    }
    ticketCount += msg.value / ticketPrice;
 }
 
 function random() private view returns (uint) {
    // global function sha algorism: keccak256
    return uint(keccak256(block.difficulty, now, players));
 }
 
 function pickWinner() public restricted {
    require(ticketCount > 0);
    require(msg.sender == manager); // only manager can pick a winner
    
    randomNum = uint(block.blockhash(block.number - 1)) % ticketCount;
    latestWinner = tickets[randomNum];
    
    winnings[latestWinner] += ticketCount;
    
    
    // uint index = random() % players.length;
    // players[index].transfer(this.balance);

    // reset the players array and (0) is initial size
    players = new address[](0);
    ticketCount = 0
 }

 function Withdraw() public {
     require(winnings[msg.sender] > 0);

    uint256 amountWon = winnings[msg.sender] * ticketPrice;
    winnings[msg.sender] = 0;
    msg.sender.transfer(amountWon);
 }
 
 // validation logic
 modifier restricted() {
    require(msg.sender == manager); // only manager can access
    _; // run all the rest of the code inside that function
 }
 
 function getPlayers() public view returns (address[]) {
    return players;
 }
}