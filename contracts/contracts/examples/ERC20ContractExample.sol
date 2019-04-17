pragma solidity ^0.5.6;

import "./MagnatBase.sol";
import "./tokens/erc20.sol";
import "./access/access-control.sol";

/**
 * @dev This is a Resource contract for Magnat Game.
 * Based on ERC-20 Token — Reference Implementation by OpenZeppelin 
 * (https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts/token/ERC20)
 */
contract ERC20ContractExample is ERC20 {
  // @dev Contract special states
  address private mbAddr; //MagnatBase Contract Address short alias
  //string private _name;
  //string private _symbol;

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
        contractType = 1;
        contractName = 'MagnatGame-IronOre-Resource';
        contractSymbol = "MGNT-IRON";
        contractShortDesc = "THIS IS IRON OREEEEEE!";
        contractOnPause = false;
        contractDeleted = false;
        contractDeletionReason = '';
        /************************* END OF CONTRACT INFO ***********************************/
        
        // @dev Saving aliases
        _name = contractName;
        _symbol = contractSymbol;
        
        // @dev Checking requirements
        require (MagnatBaseAddr != address(0));
        
        // @dev Saving states
        mbAddr = MagnatBaseAddr;
  }
    
    //address "0x5e3346444010135322268a4630d2ed5f8d09446c"
    //name    "LockTrip"
    //decimals    "18"
    //symbol  "LOC"
    //totalSupply "18585932741500854062225000"
    //owner   ""
    //lastUpdated 1528702164286
    //issuancesCount  0
    //holdersCount    36578
    //image   "https://ethplorer.io/images/loctrip.png"
    //description "Hotel Booking & Vacation…ace With 0% Commissions"
    //website "https://locktrip.com/"
    //facebook    "LockChainLOK"
    //twitter "LockChainCo"
    //reddit  "LockChainCo"
    //telegram    "https://t.me/LockTrip"
    //links   "Subreddit: https://www.r…://github.com/LockTrip\n"

    /************************************************************************************************/
    /************************************** PUBLIC FUNCTIONS*****************************************/
    /************************************************************************************************/
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintResource(
        address to, 
        uint256 value
        ) 
        public returns (bool) 
    {
        require (checkCLevel());
        _mint(to, value);
        return true;
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
    
}
