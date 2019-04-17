pragma solidity ^0.5.6;

import "./tokens/nf-token-metadata.sol";// OpenZeppelin ERC721 standart token metadata
import "./access/access-control.sol";   // AccessControl file functions
import "./000-MagnatBase.sol";          // Main MagnatBase Game file functions (already deployed)

/**
 * @dev This is a Magnat Game unique substances.
 * @dev Reference Implementation of NFToken by 0xcert (https://github.com/0xcert/ethereum-erc721)
 */
contract MagnatSubstances is
  NFTokenMetadata,
  AccessControl
{
  /* 
   * @dev Declare Contract global states
   */
  address private mbAddr;             //MagnatBase Contract Address short alias
  uint public contractId;             // This contract ID, saved in the MagnatBase Contract[] metadata
  uint16 public contractType;         // Type of the contract (1-ERC20, 2-ERC721, 3-OTHER)
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
        contractType = 721;
        contractName = 'MagnatGame-SubsnatceCollection';
        contractSymbol = "MGNT-SUB";
        contractShortDesc = "DIE HARD GAME WITH SUBSTANCES!";
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
        nftName = contractName;
        nftSymbol = contractSymbol;
        ceoAddress = _ceoAddress;
        mbAddr = _magnatBaseAddress;
  }

  /************************************************************************************************/
  /*********************************** PUBLIC FUNCTIONS *******************************************/
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
  /****************************** NFT TOKEN IMPLEMENTATION ****************************************/
  /************************************************************************************************/
  /*
   * @dev Mints a new NFT
   * @dev CLevel only
   * @dev whenNotPaused
   */
  function mintToken(
    address _to,            // The address that will own the minted NFT
    uint256 _tokenId,       // TokenId of the NFT to be minted
    string calldata _uri    // String representing RFC 3986 URI (*token metadata)
  )
    onlyCLevel
    whenNotPaused
    external
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }

  /*
   * @dev Burns a NFT
   * @dev CLevel only
   * @dev whenNotPaused
   */
  function burnToken(
    uint256 _tokenId        // TokenId (ID) of the NFT to be burned.
  )
    onlyCLevel
    whenNotPaused
    external
  {
    _burn(_tokenId);
  }

  /*
   * @dev Edit a NFT URI data
   * @dev CLevel only
   * @dev whenNotPaused
   */
  function editTokenURI(
    uint256 _tokenId,        // TokenId (ID) of the NFT to be burned.
    string calldata _uri     // String representing RFC 3986 URI (*new token metadata)
  )
    onlyCLevel
    whenNotPaused
    external
  {
    super._setTokenUri(_tokenId, _uri);
  }

  // ********************************************************************************** //
  // *********************** MARKET STRUCT IMPLEMENTATION ***************************** //
  // ********************************************************************************** //
  /*
   * @dev Struct for user offers
   */
  struct Offer {
    address payable sellerAddr;		 // Address of the token seller
    uint price;       	           // Price value for sell in WEI
    bool auction;			             // Buy it now without auction
    bool holland;			             // Is it Holland Type of auction ir not
  }

  /*
   * @dev Counter of all minted tokens
   */
  uint256 public totalOffers;

  /*
   * @dev Array of all offers for sale
   * @param uint - is an unique Market Token ID
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
   * @dev Array of the highest Token bid
   * @param uint256 - is an unique Market Token ID
   * @param Offer - is an Offer struct (array) with token market data
   */
  mapping (uint256 => Bid) public bids;

  /*
   * @dev Making address payable for a seller and buyer 
   */
  mapping (address => address payable) internal addressPayable;

  /*
   * @dev Array with pending withdrawals in WEI for sold Token
   */
  //mapping (address => uint) public pendingWithdrawals;

  /*
   * @dev Transfer money event for a bought token
   */
  event MoneyTransfer(
    uint indexed _tokenId,
    uint value,
    address indexed fromAddr,
    address indexed toAddr
  );

  // *************************************************************************************** //
  // ******************************* MARKET PUBLIC FUNCTIONS******************************** //
  // *************************************************************************************** //
  /*
   *  @dev Set token for sale
   */
  function sellToken(
      uint256 _tokenId,
      uint price,
      bool auction,
      bool holland
      )
      external
      canOperate(_tokenId)
      validNFToken(_tokenId)
      returns (bool)
  {
      require (price > 0);
      
      totalOffers++;
      // saving to array
      tokenOnSell[_tokenId] = true;
      offers[_tokenId].sellerAddr = msg.sender;
      offers[_tokenId].price = price;
      offers[_tokenId].auction = auction;
      offers[_tokenId].holland = holland;
      
      return true;
  }

  /* 
   * @dev Buy token in the sale
   */
  function buyToken(
    uint256 _tokenId,
    uint price
    )
    external
    payable
    returns (bool)
  {
    require(tokenOnSell[_tokenId]);
    require(msg.value == price);                  // Double checkng ETH value sended == price
    require(price >= offers[_tokenId].price);     // 
    require(msg.value >= offers[_tokenId].price);

    address _buyer = msg.sender;
    address payable _seller = offers[_tokenId].sellerAddr;

    _transfer(_buyer, _tokenId);
    emit MoneyTransfer(_tokenId, msg.value, _seller, msg.sender);
    _seller.transfer(msg.value);

    totalOffers--;
    delete tokenOnSell[_tokenId];
    delete offers[_tokenId];
  }

  /* 
   * @dev Get your token back from the sale
   */
  function takeBackFromSale(
    uint256 _tokenId
    )
    external
    canOperate(_tokenId)
    validNFToken(_tokenId)
    returns (bool)
  {
    totalOffers--;
    delete tokenOnSell[_tokenId];
    delete offers[_tokenId];
    return true;
  }

}