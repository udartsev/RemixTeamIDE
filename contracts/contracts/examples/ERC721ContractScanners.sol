pragma solidity ^0.5.6;

import "./tokens/nf-token-metadata.sol";// OpenZeppelin ERC721 standart token metadata
import "./access/access-control.sol";   // AccessControl file functions
import "./MagnatBase.sol";              // MagnatBase file functions (already deployed)
//import "./MagnatMarket.sol";

/**
 * @dev This is a Scanners contract for Magnat Game, implemented of NFToken with metadata extension.
 * Based on ERC-721 Token — Reference Implementation by 0xcert (https://github.com/0xcert/ethereum-erc721)
 */
contract ScannersContract is
    NFTokenMetadata
{
  // @dev Contract special states
  address private mbAddr; //MagnatBase Contract Address short alias
  //nftName - standart ERC721 token metadata by OpenZeppelin (see: ./tokens/nf-token-metadata.sol)
  //nftSymbol - standart ERC721 token metadata by OpenZeppelin (see: ./tokens/nf-token-metadata.sol)

  uint public contractID;  // This contract ID, saved in the MagnatBase Contract[] metadata
  bool contractDeployed;   // Check if contract deployed and connected to the MagnatBase Contract[]

  address public contractAddr;      // This contract address
  uint8 public contractType;        // Type of the contract (1-ERC20, 2-ERC721, 3-OTHER)
  string public contractName;       // This Contract name (for ERC721 - tokens collection name, for ERC20 - name for all tokens)
  string public contractSymbol;     // This contract symbol
  string public contractShortDesc;  // Short description of the contract
  bool public contractOnPause;      // Set contract on pause
  bool public contractDeleted;      // Deleted contract or not
  string public contractDeletionReason; // Short description of the deletion reason


  /************************************************************************************************/
  /**************************************** CONSTRUCTOR *******************************************/
  /************************************************************************************************/
  // @dev Contract constructor
  constructor(
      address MagnatBaseAddr
    ) public {

        /*********************** ENTER CONTRACT INFO HERE ********************************/
        contractAddr = address(this);
        contractType = 2;
        contractName = 'MagnatGame-Scanner';
        contractSymbol = "MGNT-SCAN";
        contractShortDesc = "DIE HARD USE SCANNER!";
        contractOnPause = false;
        contractDeleted = false;
        contractDeletionReason = '';
        /************************* END OF CONTRACT INFO ***********************************/

        // @dev Saving aliases
        nftName = contractName;
        nftSymbol = contractSymbol;

        // @dev Checking requirements
        require (MagnatBaseAddr != address(0));

        // @dev Saving states
        mbAddr = MagnatBaseAddr;
  }

  /************************************************************************************************/
  /************************************** PUBLIC FUNCTIONS*****************************************/
  /************************************************************************************************/
  /**
   * @dev Get a Scanner metadata from MagnatBase contract.
   */
  function getScannerByID(uint id)
    public view returns (
        uint,
        uint8,
        uint8,
        string memory,
        uint64,
        string memory,
        address,
        uint8,
        bool,
        uint64,
        bool,
        address
    ){
      return MagnatBase(mbAddr).getScannerByID(id);
   }



    // @dev Check CLevel restrictions from MagnatBase
    function checkCLevel() public view returns(bool) {
        address _address = msg.sender;
        return MagnatBase(mbAddr).checkCLevel(_address);
    }

    // @dev Check CEO restrictions from MagnatBase
    function checkCEOLevel() public view returns(bool) {
        address _address = msg.sender;
        return MagnatBase(mbAddr).checkCEOLevel(_address);
    }

    // @dev whenNotPaused;
    function checkNotPaused() public view returns(bool) {
        return MagnatBase(mbAddr).checkNotPaused();
    }

  /************************************************************************************************/
  /****************************** NFT TOKEN PUBLIC ACTIONS ****************************************/
  /************************************************************************************************/
  /**
   * @dev Mints a new NFT.
   * @dev CLevel only
   * @dev whenNotPaused
   */
  function mintToken(
    address _to,            // The address that will own the minted NFT
    uint256 _tokenId,       // TokenId of the NFT to be minted
    string calldata _uri    // String representing RFC 3986 URI (*token metadata)
  )
    external
  {
    require(checkCLevel());
    require(checkNotPaused());
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }

  /**
   * @dev Burns a NFT.
   * @dev CLevel only
   * @dev whenNotPaused
   */
  function burnToken(
    uint256 _tokenId        // TokenId (ID) of the NFT to be burned.
  )
    external
  {
    require(checkCLevel());
    require(checkNotPaused());
    //if (!checkNotPaused()) {require(checkCEOLevel());}
    _burn(_tokenId);
  }

  /**
   * @dev Edit a NFT URI data.
   * @dev CLevel only
   * @dev whenNotPaused
   */
  function editTokenURI(
    uint256 _tokenId,        // TokenId (ID) of the NFT to be burned.
    string calldata _uri     // String representing RFC 3986 URI (*new token metadata)
  )
    external
  {
    require(checkCLevel());
    require(checkNotPaused());
    super._setTokenUri(_tokenId, _uri);
  }

  // ********************************************************************************** //
  // *************************** MARKET IMPLEMENTATION ******************************** //
  // ********************************************************************************** //

    struct Offer {
        address payable sellerAddr;		// Address of the token seller
        uint price;       	// Price value for sell in WEI
        bool auction;			// Buy it now without auction
        bool holland;			// Is it Holland Type of auction ir not
    }

    struct Bid {
      address bidderAddr;   // Bidder Address
        bool hasBid;      // Bidder did a bit or not
        uint valueEth;      // Bidding value in ETH
    }

    // @dev Array of all tokens for sale.
    // @param uint - is an unique Market Token ID
    // @param Offer - is an Offer struct (array) with token market data
    mapping (uint256 => Offer ) public tokensForSale;
    uint256 public totalTokensForSale;

    // @dev Array of the highest Token bid
    mapping (uint256 => Bid) public tokenBids;

    //
    mapping (address => address payable) internal addressPayable;

    // @dev Array with pending withdrawals in ETH for sold Token
    //mapping (address => uint) public pendingWithdrawals;

    // @dev Transfer money value from buyer to seller
    event MoneyTransfer(
      uint indexed _tokenId,
      uint value,
      address indexed fromAddr,
      address indexed toAddr
    );


    //****************************** PUBLIC FUNCTIONS *********************************//
    // @dev Set token for sale
    function sellToken(
        uint256 _tokenId,
        uint price,
        bool isAuction,
        bool isHolland
        )
        external
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
        require(isAuction == false);
        require(isHolland == false);
        totalTokensForSale++;
        // saving to array
        tokenOnSell[_tokenId] = true;
        tokensForSale[_tokenId].sellerAddr = msg.sender;
        tokensForSale[_tokenId].price = price;
        tokensForSale[_tokenId].auction = false;
        tokensForSale[_tokenId].holland = false;
    }
    // @dev Get your token back from the sale
    function takeBackFromSale(
        uint256 _tokenId
        )
        external
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
        totalTokensForSale--;
        delete tokenOnSell[_tokenId];
        delete tokensForSale[_tokenId];
    }

    function buyToken(
        uint256 _tokenId,
        uint price
        )
        external
        payable
        returns (bool)
    {
        require(tokenOnSell[_tokenId]);
        require(msg.value == price);
        require(price >= tokensForSale[_tokenId].price);
        require(msg.value >= tokensForSale[_tokenId].price);

        //uint valueETH = msg.value;
        address buyer = msg.sender;
        address payable seller = tokensForSale[_tokenId].sellerAddr;

        _transfer(buyer, _tokenId);
        emit MoneyTransfer(_tokenId, msg.value, seller, msg.sender);
        seller.transfer(msg.value);

        totalTokensForSale--;
        delete tokenOnSell[_tokenId];
        delete tokensForSale[_tokenId];
    }

  // ********************************************************************************** //
}