// pragma solidity >=0.4.22 <0.7.0;
pragma solidity ^0.7.0;

contract LotteryGenerator {
    address[] public lotteries;
    struct lottery{
        uint index;
        address manager;
    }
    mapping(address => lottery) lotteryStructs;

    // Creates a new lottery with name as the index 
    function createLottery(string name) public {
        require(bytes(name).length > 0);
        address newLottery = new Lottery(name, msg.sender);
        lotteryStructs[newLottery].index = lotteries.push(newLottery) - 1;
        lotteryStructs[newLottery].manager = msg.sender;

        // event
        LotteryCreated(newLottery);
    }

    // Getter function for lottery 
    function getLotteries() public view returns(address[]) {
        return lotteries;
    }


    function deleteLottery(address lotteryAddress) public {
        // Ensures that only manager can delete a lottery
        require(msg.sender == lotteryStructs[lotteryAddress].manager);

        // Swaps the last lottery with the lottery to delete and decrease the lottery length
        uint indexToDelete = lotteryStructs[lotteryAddress].index;
        address lastAddress = lotteries[lotteries.length - 1];
        lotteries[indexToDelete] = lastAddress;
        lotteries.length --;
    }

    // Events
    // Can be emitted and stored by the msg.sender address
    event LotteryCreated(
        address lotteryAddress
    );
}

contract Lottery {
    // name of the lottery
    string public lotteryName;
    // Creator of the lottery contract
    address public manager;

    // variables for players
    struct Player {
        string name;
        uint entryCount;
        uint index;
    }

    address[] public addressIndexes;

    // maps the address to Player
    mapping(address => Player) players;
    address[] public lotteryBag;

    // Variables for lottery information
    Player public winner;
    bool public isLotteryLive;
    uint public maxEntriesForPlayer;
    uint public ethToParticipate;

    // constructor
    function Lottery(string name, address creator) public {
        manager = creator;
        lotteryName = name;
    }

    // Let users participate by sending eth directly to contract address
    function Participate() public payable {
        // player name will be unknown
        participate("Unknown");
    }

    function participate(string playerName) public payable {
        require(bytes(playerName).length > 0);
        require(isLotteryLive);
        require(msg.value == ethToParticipate * 1 ether);
        require(players[msg.sender].entryCount < maxEntriesForPlayer);

        if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = 1;
            players[msg.sender].name = playerName;
            players[msg.sender].index = addressIndexes.push(msg.sender) - 1;
        } else {
            players[msg.sender].entryCount += 1;
        }

        lotteryBag.push(msg.sender);
    
        // event
        PlayerParticipated(players[msg.sender].name, players[msg.sender].entryCount);
    }

    // Here we control the number of players we can set maxEntries to 5
    // Here we can control the minimum amount of eth to participate 
    function activateLottery(uint maxEntries, uint ethRequired) public restricted {
        isLotteryLive = true;
        maxEntriesForPlayer = maxEntries == 0 ? 1: maxEntries;
        ethToParticipate = ethRequired == 0 ? 1: ethRequired;
    }

    function declareWinner() public restricted {
        require(lotteryBag.length > 0);

        // Uses a random number generator (pseudo random function?) and sends the balance to that person's address
        uint index = generateRandomNumber() % lotteryBag.length;
        lotteryBag[index].transfer(this.balance);
         
        winner.name = players[lotteryBag[index]].name;
        winner.entryCount = players[lotteryBag[index]].entryCount;

        // empty the lottery bag and indexAddresses
        lotteryBag = new address[](0);
        addressIndexes = new address[](0);

        // Mark the lottery inactive
        isLotteryLive = false;
    
        // event
        WinnerDeclared(winner.name, winner.entryCount);
    }

    function getPlayers() public view returns(address[]) {
        return addressIndexes;
    }

    function getPlayer(address playerAddress) public view returns (string, uint) {
        if (isNewPlayer(playerAddress)) {
            return ("", 0);
        }
        return (players[playerAddress].name, players[playerAddress].entryCount);
    }

    function getWinningPrice() public view returns (uint) {
        return this.balance;
    }

    // Private functions
    function isNewPlayer(address playerAddress) private view returns(bool) {
        if (addressIndexes.length == 0) {
            return true;
        }
        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }

    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() private view returns(uint) {
        // keccak256 is a Ethereum-3 SHA 256 random number generator
        // what is block.difficulty and now 
        // keccak256 concatenates parameters together 
        return uint(keccak256(block.difficulty, now, lotteryBag));
    }

    // Modifiers
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    // Events
    event WinnerDeclared( string name, uint entryCount );
    event PlayerParticipated( string name, uint entryCount );
}