pragma solidity ^0.5.6;

import "./tokens/erc20.sol";          // OpenZeppelin ERC20 standart token
import "./access/access-control.sol"; // AccessControl file functions
import "./000-MagnatBase.sol";        // Main MagnatBase Game file functions (already deployed)

/**
 * @dev This is a Resource contract for MagnatGame
 * @dev Reference Implementation of ERC20 by 0xcert 
 * (https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts/token/ERC20)
 */
contract MagnatResources is 
  ERC20,
  AccessControl
{
  using SafeMath for uint256;

  /* 
   * @dev Declare Contract global states
   */
  address private mbAddr;             //MagnatBase Contract Address short alias
  uint public contractId;             // This contract ID, saved in the MagnatBase Contract[] metadata
  uint8 public contractType;          // Type of the contract (1-ERC20, 2-ERC721, 3-OTHER)
  string public contractName;         // This Contract name (for ERC721 - tokens collection name, for ERC20 - name for all tokens)
  string public contractSymbol;       // This contract symbol
  string public contractShortDesc;    // Short description of the contract
  bool public contractDeleted;        // Deleted contract or not
  string public contractDeletionReason; // Short description of the deletion reason


  /************************************************************************************************/
  /**************************************** CONSTRUCTOR *******************************************/
  /************************************************************************************************/
  /*
   * @dev Contract constructor
   */
  constructor(
      address _magnatBaseAddress,
      address _ceoAddress
    ) public {
        
        /*********************** ENTER CONTRACT INFO HERE ********************************/
        contractType = 201;
        contractName = 'MagnatGameResource-IronOre';
        contractSymbol = "MGNT-IRON";
        contractShortDesc = "THIS IS IRON OREEEEEE!";
        contractDeleted = false;
        contractDeletionReason = '';
        /************************* END OF CONTRACT INFO ***********************************/
        
        /* 
         * @dev Checking requirements
         */
        require (_magnatBaseAddress != address(0));
        require (_ceoAddress != address(0));

        /* 
         *@dev Saving aliases
         */
        _name = contractName;
        _symbol = contractSymbol;
        ceoAddress = _ceoAddress;
        mbAddr = _magnatBaseAddress;  
  }

  /************************************************************************************************/
  /************************************** PUBLIC FUNCTIONS*****************************************/
  /************************************************************************************************/
  /*
   * @dev Setting contractId function
   * @note Before setting, new contract must be saved in the MagnatBase Contract[] contracts array
   * @note The contract id included in the MagnatBase idContract[] array
   */ 
  function setContractId()
    external returns(uint256){
      require (MagnatBase(mbAddr).checkValid(address(this)));
      contractId = MagnatBase(mbAddr).getContractId(address(this));
      return contractId;
  }

  /************************************************************************************************/
  /******************************* STANDART TOKEN IMPLEMENTATION **********************************/
  /************************************************************************************************/
  /*
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
  */
  function mintResource(
    address to, 
    uint256 value
  )
    onlyCLevel
    whenNotPaused
    public returns (bool) 
  {
    _mint(to, value);
    return true;
  }
  
  /*
   * @dev Burns a specific amount of tokens.
   * @param value The amount of token to be burned.
   */
  function burnResource(
    uint256 value
  ) 
    onlyCLevel
    public 
  {
    _burn(msg.sender, value);
  }

  /*
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param from address The account whose tokens will be burned.
   * @param value uint256 The amount of token to be burned.
   */
  function burnFrom(
    address from, 
    uint256 value
  ) 
    onlyCLevel
    public 
  {
    _burnFrom(from, value);
  }

  // ********************************************************************************** //
  // *********************** MARKET STRUCT IMPLEMENTATION ***************************** //
  // ********************************************************************************** //
  /*
   * @dev Struct for user offers
   */
  struct Offer {
    address payable sellerAddr;    // Address of the token seller
    uint256 quantity;              // Quantity for sale 
    uint price;                    // Price value for sell in WEI
    bool auction;                  // Buy it now without auction
    bool holland;                  // Is it Holland Type of auction ir not
  }

  /*
   * @dev Counter of all minted tokens available for sale
   */
  uint256 public totalResourcesForSale;

  /*
   * @dev Counter of all offers for sale
   */
  uint256 public totalOffers;

  /*
   * @dev Array of all offers for sale
   * @param uint256 - is an unique Sale Offer ID
   * @param Offer - is an Offer struct (array) with token market data
   */
  mapping (uint256 => Offer ) public offers;

  /*
   * @dev Struct for user bids to buy token
   */
  struct Bid {
    address bidderAddr;   // Bidder Address
      bool hasBid;        // Bidder did a bit or not
      uint price;         // Bidding value in WEI
  }  

  /*
   * @dev Array of the highest bid
   * @param uint - is an unique Market Token ID
   * @param Offer - is an Offer struct (array) with token market data
   */
  mapping (uint256 => Bid) public offerBids;

  /*
   * @dev Making address payable for a seller and buyer 
   */
  mapping (address => address payable) internal addressPayable;

  /*
   * @dev Making User token balance blocked for sale
   */
  mapping (address => uint256) internal _blockedBalances;

  /*
   * @dev Array with pending withdrawals in WEI for sold Token
   */
  //mapping (address => uint) public pendingWithdrawals;

  /*
   * @dev Transfer money event for a bought token
   */
  event MoneyTransfer(
    address indexed fromAddr,
    address indexed toAddr,
    uint256 indexed quantity,
    uint value
  );

  /*
   * @dev Check if token balance is OK
   */
  modifier tokenBalanceOK(uint256 _quantity) {
    require(_quantity >= _balances[msg.sender].sub(_blockedBalances[msg.sender]));
    _;
  }
  
  /*
   * @dev Check if user have tokens
   */
  modifier isTokenOwner(address _address) {
    require(_balances[_address] > 0);
    _;
  }

  /*
   * @dev Check if user is an Offer owner
   */
  modifier isOfferOwner(address _seller,uint256 _offerId) {
    require(_seller == offers[_offerId].sellerAddr);
    _;
  }

  // *************************************************************************************** //
  // ******************************* MARKET PUBLIC FUNCTIONS******************************** //
  // *************************************************************************************** //
  /*
   *  @dev Set token for sale
   */
  function sellResource(
      uint256 quantity,
      uint price,
      bool auction,
      bool holland
      )
      external
      returns (uint256)
  { 
      require (_balances[msg.sender] > 0);
      require (quantity > 0);
      require (quantity <= _balances[msg.sender]);
      require (price > 0);
      
      if(_blockedBalances[msg.sender] > 0) {
        require(quantity <= _balances[msg.sender].sub(_blockedBalances[msg.sender]));
        _blockedBalances[msg.sender] = _blockedBalances[msg.sender].add(quantity);
      } else {
        _blockedBalances[msg.sender] = quantity;
      }
      
      totalResourcesForSale = totalResourcesForSale.add(quantity);
      uint256 _offerId = totalOffers++;

      // saving to array
      offers[_offerId].sellerAddr = msg.sender;
      offers[_offerId].quantity = quantity;
      offers[_offerId].price = price;
      offers[_offerId].auction = auction;
      offers[_offerId].holland = holland;
      
      return _offerId;
  }

  /* 
   * @dev Buy token in the sale
   */
  function buyResource(
    uint256 _offerId,
    uint price
    )
    external
    payable
    returns (bool)
  {
    require(msg.value == price);                  // Double checkng ETH value sended == price
    require(price >= offers[_offerId].price);     // 
    require(msg.value >= offers[_offerId].price);

    address _buyer = msg.sender;
    address payable _seller = offers[_offerId].sellerAddr;
    uint256 _quantity = offers[_offerId].quantity;

    _blockedBalances[_seller] = _blockedBalances[_seller].sub(offers[_offerId].quantity);

    _transfer(_seller, _buyer, _quantity);
    emit MoneyTransfer(_seller, _buyer, _quantity, msg.value);
    _seller.transfer(msg.value);

    totalOffers--;
    totalResourcesForSale = totalResourcesForSale.sub(_quantity);
    delete offers[_offerId];
  }

  /* 
   * @dev Get your token back from the sale
   */
  function takeBackFromSale(
    uint256 _offerId
    )
    external
    isOfferOwner(msg.sender, _offerId)
    returns (bool)
  {
    totalOffers--;

    _blockedBalances[msg.sender] = _blockedBalances[msg.sender].sub(offers[_offerId].quantity);
    totalResourcesForSale = totalResourcesForSale.sub(offers[_offerId].quantity);

    delete offers[_offerId];
    return true;
  }
 
}
