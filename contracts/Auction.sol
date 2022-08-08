pragma solidity ^0.8.0;

import './KhlopiachyiToken.sol';
import "@openzeppelin/contracts/access/Ownable.sol";


contract Auction is Ownable {
    struct BidStruct {
        uint256 amount;
        uint256 placed;
    }

    KhlopiachyiToken public rewardToken;
    address private admin;

    uint public reward;
    uint256 public duration;
    uint256 public endAt;
    bool public started;
    bool public ended;

    address public highestBidders;
    uint256 public highestBid;
    uint256 public maxBidAmountPerUser;
    uint256 public maxBidAmount;
    uint256 private winnersAmount;
    uint256 private rewardAmount;

    mapping(address => BidStruct) public bids;
    mapping(address => uint256) public amountPerUser;
    address[] private participants;

    constructor(address _token, uint256 _duration, uint256 _minBid, uint256 _maxBidAmountPerUser, uint256 _maxBidAmount, uint256 _winnersAmount, uint256 _reward) {
        rewardToken = KhlopiachyiToken(_token);
        highestBid = _minBid;
        duration = _duration;
        admin = msg.sender;
        started = false;
        ended = false;
        maxBidAmountPerUser = _maxBidAmountPerUser;
        maxBidAmount = _maxBidAmount;
        winnersAmount = _winnersAmount;
        rewardAmount = _reward;
    }

    modifier isStarted() {
        require(started, 'Auction is not started yet');

        _;
    }

    function start(uint256 _rewardAmount) external onlyOwner {
        require(!started, 'Auction already started');

        started = true;
        endAt = block.timestamp + uint64(duration);
        rewardAmount = _rewardAmount;
    }

    function bid() external payable isStarted {
        require(block.timestamp < endAt, 'Auction is finished');
        require(msg.value > highestBid, "Your values is less than the highestBid");
        require(amountPerUser[msg.sender] < maxBidAmountPerUser, 'You reached max bids amount');

        amountPerUser[msg.sender] = amountPerUser[msg.sender] + 1;
        bids[msg.sender].amount = msg.value;
        bids[msg.sender].placed = block.timestamp;
        highestBid = msg.value;

        if (participants.length < maxBidAmount) {
            participants.push(msg.sender);
        } else {
            payable(participants[0]).transfer(bids[participants[0]].amount);
            delete bids[participants[0]];

            for(uint256 i = 0; i < maxBidAmount - 1; i += 1) {
                participants[i] = participants[i+1];
            }

            participants.pop();
            participants.push(msg.sender);
        }
    }

    function end() external isStarted {
        require(block.timestamp >= endAt, 'Auction is finished');

        ended = true;
    }

    function withdraw() external isStarted {
        require(ended, "Auction is not over yet");
        uint256 reward;


        rewardToken.transfer(msg.sender, reward);
    }
}