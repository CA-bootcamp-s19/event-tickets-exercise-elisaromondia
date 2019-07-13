pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTickets.sol";
import "../contracts/EventTicketsV2.sol";

// Proxy contract for testing throws
contract ThrowProxy {
	address public target;
	bytes data;

	constructor(address _target) public {
		target = _target;
	}

	//prime the data using the fallback function.
	function() external {
		data = msg.data;
	}

	function execute() external returns (bool) {
		(bool r, ) = target.call(data);
		return r;
	}

	function execute(uint val) external returns (bool) {
		(bool r, ) = target.call.value(val)(data);
		return r;
	}

}

contract TestEventTicket {

	uint public initialBalance = 1 ether;

	string description = "description";
	string url = "URL";
	uint ticketNumber = 100;
	EventTickets testTicketEvent;
	uint ticketPrice = 100 wei;

	function beforeEach() public {
		testTicketEvent = new EventTickets(description, url, ticketNumber);
	}

	function testSelf() public {
		Assert.equal(address(this).balance, 1 ether, 'not sufficient balance');
	}

	function testSetup()
		public
	{
		Assert.equal(testTicketEvent.owner(), address(this), 'deploying restricted to the the owner');
		(, , , , bool isOpen) = testTicketEvent.readEvent();
		Assert.equal(isOpen, true, 'event must be open');
	}
	function testFunctions() public {
		(string memory eventDescription, string memory website, uint totalTickets, uint sales, ) = testTicketEvent.readEvent();
		Assert.equal(eventDescription, description, "descriptions should match");
		Assert.equal(website, url, "urls should match");
		Assert.equal(totalTickets, ticketNumber, "total tickets should match");
		Assert.equal(sales, 0, "sales should start from 0");
	}

	function testBuyTickets() public payable {
		testTicketEvent.buyTickets.value(ticketPrice)(1);
		(, , , uint sales, ) = testTicketEvent.readEvent();
		Assert.equal(sales, 1, 'sales should be 1');
	}

	function testBuyTicketsFund() public {
		ThrowProxy throwproxy = new ThrowProxy(address(testTicketEvent));
		EventTickets(address(throwproxy)).buyTickets(1);
		bool r = throwproxy.execute(ticketPrice - 1);
		Assert.isFalse(r, "error when fund are not enough to buy tickets");
	}

	function afterEach() public {
		testTicketEvent.endSale();
	}

	function() external payable {
	}

}
