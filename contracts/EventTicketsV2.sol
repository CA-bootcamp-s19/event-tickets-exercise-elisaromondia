pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint   PRICE_TICKET = 100 wei;
    address payable public owner;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idLedger;


    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */

    struct Event {

        string desc;
        string url;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;

    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier isOwner() { require( msg.sender == owner, "Not owner");_;}
    modifier realBuyer(address _buyer, uint _eventid) { require( events[_eventid].buyers[_buyer] > 0  );_;}
    modifier paidEnough(uint _quantity) { require( msg.value >= PRICE_TICKET * _quantity ); _;}
    modifier isOpened(uint _eventid) { require(events[_eventid].isOpen == true ); _;}
    modifier enoughTicket(uint _eventid, uint _quantity) { require( events[_eventid].totalTickets - events[_eventid].sales > _quantity ); _;}
    modifier refund(uint _quantity) { _; msg.sender.transfer(msg.value - PRICE_TICKET * _quantity); }

    constructor() public {

        owner = msg.sender;
        idLedger = 0;

    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */

    function addEvent(string memory _desc, string memory _url, uint _ticketNum)
        public
        isOwner()
        returns(uint)
    {
        uint eventId = idLedger;
        Event memory newEvent = Event({desc: _desc, url: _url, totalTickets: _ticketNum, sales: 0, isOpen: true});
        events[eventId] = newEvent;
        emit LogEventAdded(newEvent.desc,newEvent.url,newEvent.totalTickets,eventId);
        idLedger++;
        return(eventId);
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */

    function readEvent(uint _id)
        public
        view
        returns(string memory desc, string memory url, uint ticketsNum, uint sales, bool isOpen)
    {
        return(events[_id].desc,events[_id].url,events[_id].totalTickets,events[_id].sales,events[_id].isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint _id, uint _quantity)
        payable
        public
        paidEnough(_quantity)
        isOpened(_id)
        enoughTicket(_id,_quantity)
        refund(_quantity)
    {

        events[_id].buyers[msg.sender] += _quantity;
        events[_id].sales += _quantity;
        emit LogBuyTickets( msg.sender, _id , _quantity );

    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */

    function getRefund(uint _id)
        payable
        public
        realBuyer(msg.sender, _id)

    {
        uint ticketquantity = events[_id].buyers[msg.sender];
        events[_id].sales -= ticketquantity;
        msg.sender.transfer(ticketquantity * PRICE_TICKET);
        emit LogGetRefund(msg.sender, _id, ticketquantity);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */

    function getBuyerNumberTickets(uint _id)
        public
        view
        realBuyer(msg.sender, _id)
        returns(uint _numPurchased)
    {
        uint number = events[_id].buyers[msg.sender];
        return(number);
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */

    function endSale(uint _id)
        payable
        public
        isOwner()
        isOpened(_id)

    {
        uint balance = events[_id].sales * PRICE_TICKET;
        owner.transfer(balance);
        events[_id].isOpen = false;
        emit LogEndSale( owner, balance);

    }

}
