pragma solidity ^0.5.6;

import "./access/access-control.sol";   // AccessControl file functions
import "./MagnatBase.sol";              // MagnatBase file functions (already deployed)
import "./math/safe-math.sol";
import "./ERC721Scanners.sol";

/*
 * @info This is a MagnatMarket contract of the Magnat game.
 * Allows Gamers (Users) to sell/buy items, resources, buildings, etc...
 */
contract MagnatMarket {
	using SafeMath for uint;

	// @dev mapping which holds all the possible addresses which are allowed to interact with the contract
    //mapping (address => bool) approvedAddressList;

    // @dev IDEA for 721 tokens all in one ids:
    // mapping (id => tokenId) 721tokensArray;
    // @dev или хранить ВСЕ 721 токены в одном контракте?
    // тогда получаем список uniqueID всех выпущенных токенов...

    //address tokenOwner;

    // @dev Mapping from NFT ID are selling on the Market
    //mapping (uint256 => bool) internal tokenOnSell;

    // @dev Selling price mapping _tokenId => ETH
    //mapping (uint256 => uint) public sellingPrice;

    // @dev Array with all balances
    //mapping (address => uint256) public balanceOf;

    struct Offer {
        address sellerAddr;		// Address of the token seller
        uint price;       	// Price value for sell in ETH
        bool auction;			// Buy it now without auction
        bool holland;			// Is it Holland Type of auction ir not
    }

    struct Bid {
    	address bidderAddr;		// Bidder Address
        bool hasBid;			// Bidder did a bit or not
        uint valueEth;			// Bidding value in ETH
    }

    // @dev Array of all tokens for sale.
    // @param uint - is an unique Market Token ID
    // @param Offer - is an Offer struct (array) with token market data
    mapping (uint256 => Offer ) public tokensForSale;
    uint256 public totalTokensForSale;

    // @dev Array of the highest Token bid
    mapping (uint256 => Bid) public tokenBids;

    // @dev Array with pending withdrawals in ETH for sold Token
    mapping (address => uint) public pendingWithdrawals;

    // @dev Mapping from NFT ID are selling on the Market (Magnat Market option)
    mapping (uint256 => bool) internal tokenOnSell; //same as tokensForSale but for better impl.

    //*********************************************************************************//
    //****************************** PUBLIC FUNCTIONS *********************************//
    //*********************************************************************************//

    // putForSale
    // takeBackFromSale

    function putForSale(
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

        address tokenOwner = idToOwner[_tokenId];

        // saving to array
        tokenOnSell[_tokenId] = true;
        tokensForSale[_tokenId].sellerAddr = tokenOwner;
        tokensForSale[_tokenId].price = price;
        tokensForSale[_tokenId].auction = false;
        tokensForSale[_tokenId].holland = false;
    }

}