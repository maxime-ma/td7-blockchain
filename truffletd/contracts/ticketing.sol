pragma solidity >=0.4.25;



contract ticketingSystem {
  

  mapping(uint => Artist) public artistsRegister;

  struct Artist
  {
    bytes32 name;
    address owner;
    uint artistCategory;
    uint totalTicketSold;
  }

  event createdAnArtist(uint artistNumber);

  uint idA = 1;

  function createArtist( bytes32 _name, uint _artistCategory )
  public
  {
    artistsRegister[idA].name = _name;
    artistsRegister[idA].artistCategory = _artistCategory;
    artistsRegister[idA].owner = msg.sender;
    
    emit createdAnArtist(idA);

    idA = idA + 1;
  }  


  function modifyArtist( uint _id, bytes32 newName, uint newCategory, address newAdd)
  public
  {
    require(artistsRegister[_id].owner == msg.sender);
    artistsRegister[_id].owner = newAdd;
    artistsRegister[_id].name = newName;
    artistsRegister[_id].artistCategory = newCategory;
  }


  mapping(uint => Venue) public venuesRegister;


  struct Venue
  {
    address owner;
    bytes32 name;
    uint capacity;
    uint standardComission;

  }


  event createdAVenue(uint venueNumber);

  uint idV = 1;

  function createVenue( bytes32 _name, uint _capacity, uint _standardComission )
  public
  {
    venuesRegister[idV].name = _name;
    venuesRegister[idV].capacity = _capacity;
    venuesRegister[idV].owner = msg.sender;
    venuesRegister[idV].standardComission = _standardComission;
    
    emit createdAVenue(idV);

    idV = idV + 1;
  }

  function modifyVenue( uint _idV, bytes32 newName, uint newCapacity, uint newComission, address newAdd)
  public
  {
    require(venuesRegister[_idV].owner == msg.sender);
    venuesRegister[_idV].owner = newAdd;
    venuesRegister[_idV].name = newName;
    venuesRegister[_idV].capacity = newCapacity;
    venuesRegister[_idV].standardComission = newComission;
  }



  mapping(uint => Concert) public concertsRegister;

  struct Concert
  {
    address owner;
    uint concertDate;
    uint numberPlace;
    uint artistId;
    uint venueId;
    bool validatedByVenue;
    bool validatedByArtist;
    uint price;

    uint totalSoldTicket;
    uint totalMoneyCollected;
  }


  event createdAConcert(uint concertNumber);

  uint idC = 1;


  function createConcert(uint _artistId, uint _venueId, uint _concertDate, uint _ticketPrice)
  public
  returns (uint concertNumber)
  {
    require(_concertDate >= now);
    require(artistsRegister[_artistId].owner != address(0));
    require(venuesRegister[_venueId].owner != address(0));
    concertsRegister[idC].concertDate = _concertDate;
    concertsRegister[idC].artistId = _artistId;
    concertsRegister[idC].venueId = _venueId;
    concertsRegister[idC].price = _ticketPrice;
    validateConcert(idC);
    concertNumber = idC;
    
    emit createdAConcert(idC);
    idC +=1;
  }


  function validateConcert(uint _concertId)
  public
  {
    require(concertsRegister[_concertId].concertDate >= now);

    if (venuesRegister[concertsRegister[_concertId].venueId].owner == msg.sender)
    {
      concertsRegister[_concertId].validatedByVenue = true;
    }
    if (artistsRegister[concertsRegister[_concertId].artistId].owner == msg.sender)
    {
      concertsRegister[_concertId].validatedByArtist = true;
    }
  }

  mapping (uint => Ticket)  public ticketsRegister;

  uint _numberOfTickets = 0;

  struct Ticket 
  {
    address owner;
    uint artistId;
    uint concertId;
    uint venueId;
    uint concertDate;
    uint amountPaid;
    uint salePrice;
    bool isRefundable;
    bool isAvailable;
    bool isAvailableForSale;
  }

  event createdATicket(uint num);

  function emitTicket(uint _concertId, address _receiver) 
  public 
  {

        emit createdATicket(_numberOfTickets);
  }


  function buyTicket(uint _concertId) 
  public payable 
  {
    Concert storage concert = concertsRegister[_concertId];
    artistsRegister[concert.artistId].totalTicketSold++;
    concert.totalSoldTicket++;
    concert.totalMoneyCollected += msg.value;
    _numberOfTickets++;
    ticketsRegister[_numberOfTickets] = Ticket(msg.sender, concert.artistId, _concertId, concert.venueId, concert.concertDate, msg.value, 0, true, true, false);
  }


  function transferTicket(uint _ticketId, address _receiver) 
  public 
  {
    require(msg.sender == ticketsRegister[_ticketId].owner);
    ticketsRegister[_ticketId].owner = _receiver;
  }



  function offerTicketForSale(uint _ticketId, uint _salePrice) 
  public 
  {
    require(msg.sender == ticketsRegister[_ticketId].owner);
    require(_salePrice <= ticketsRegister[_ticketId].amountPaid);
    ticketsRegister[_ticketId].isAvailableForSale = true;
    ticketsRegister[_ticketId].salePrice = _salePrice;
  }


  function buySecondHandTicket(uint _ticketId) 
  public payable 
  {
    require(ticketsRegister[_ticketId].isAvailableForSale);
    require(msg.value == ticketsRegister[_ticketId].salePrice);
    ticketsRegister[_ticketId].owner = msg.sender;
    ticketsRegister[_ticketId].amountPaid = msg.value;
    if (!ticketsRegister[_ticketId].isRefundable) 
    {
        ticketsRegister[_ticketId].isRefundable = true;
    }
  }


    function useTicket(uint _ticketId) 
    public 
    {
        require(msg.sender == ticketsRegister[_ticketId].owner);
        require(concertsRegister[ticketsRegister[_ticketId].concertId].validatedByVenue);
        Ticket storage ticket = ticketsRegister[_ticketId];
        ticket.owner = address(0);
        ticket.isAvailable = false;
        ticket.isRefundable = false;
        if (ticket.isAvailableForSale) 
        {
            ticket.isAvailableForSale = false;
            ticket.salePrice = 0;
        }
    }

  function redeemTicket(uint _ticketId) 
  public 
  {
    require(msg.sender == ticketsRegister[_ticketId].owner);
    Ticket memory ticket = ticketsRegister[_ticketId];
    Concert storage concert = concertsRegister[ticket.concertId];
    concert.totalSoldTicket--;
    concert.totalMoneyCollected -= ticket.amountPaid;
    msg.sender.transfer(ticket.amountPaid);
  }
  
}










