pragma solidity ^0.5.6;

import "./access/access-control.sol";

/* 
 * @title MagnatBase Contract. Holds all common structs, events and base variables.
 * @note MagnatBase is the main Game contract. Here includes basic data about MagnatGame 
 * entities, information about players, clans, instruments, reaources and other substances...
 * Anyone can check all the contracts and ints substances involved in the game, irrelevant 
 * is it ERC20, ERC721 or (whether) any other contract, connected to the Game. You can see 
 * all additional data just follow by connected contract address.
 *
 * @dev MagnatGame Contracts, Tokens and it`s types are using (or will be) in the Game.
 * @note Totally its the Game Base Index System, where first two numbers - is and index
 * of the Game substance. For example: "71XXXXXXXX...^n" for non-fungable substances 
 * or just "71X" for regular substances (like resources) can mean:
 *  [71]    - substance or contract Type index
 *  [XX..]  - unique token number if exists
 *  
 * @note max tokens: 10^18-1
 * @note max tokens for one Account <= 10000
 *
 *  ERC721  for:
 *  721 - Scanner[] scanners;       // Non-fungable game substances
 *  
 *  ERC20  for:
 *  20 - Resource[] resources;     // Some unique or collectible resources
 *  201 - ironore resource; 
 *  21 - Clan[] clans;             // Clans array and of the Game
 *  22 - Minion[] minions;         // Game minions
 *  
 *  Struct or other:
 *  331 - Warehouse[] warehouses;   // User warehouse buildings
 *  332 - Market[] markets;         // World, country, region, city or even private markets
 *  333 - MiningField[] miningfields;// Minings Fields are in the game
 */

contract MagnatBase is AccessControl {

	//*********************************************************************************//
    //********************************** CONSTRUCTOR **********************************//
    //*********************************************************************************//
    /* 
     * @dev MagnatBase contract counctuctor
     */
    constructor(
        address _ceoAddress
        ) public {
    	// @dev Add CEO addres of the Game
        ceoAddress = _ceoAddress;
    }

    //*********************************************************************************//
    //*************************** ALL CONTRACTS STRUCT ********************************//
    //*********************************************************************************//
    /* 
     * @dev Struct (data array), wich includes all contracts connected to the Game.
     * The id of the struct is an actual Contract Identification Number (contractID).
     */
    struct Contract {
    	address contractAddr;	        // Deployed resource contract address
    	uint8 contractType;		        // Type of the contract (721, 20, 331 etc...)
        string contractName;            // Name of the contract
    }

    /* 
     * @dev A mapping from GameContract[] array to count of total connected contracts
     */
    mapping (uint256 => Contract) public contracts;

    /* 
     * @dev A mapping for a valid connected contracts
     */
    mapping (address => bool) internal validContract;

     /* 
     * @dev A mapping for connected contracts and its ids
     */
    mapping (address => uint256) internal idContract;

    /* 
     * @param totalContracts - counted number of GameContract contractIDs
     */
    uint256 public totalContracts;

    /*
     * @dev (FUTURE OPTION) Struct of the Contracts in moderation for future voting
     */
   /* struct ContractModeration {
        address contractAddr;           // Deployed resource contract address
        uint8 contractType;             // Type of the contract (1-ERC20, 2-ERC721, 3-OTHER)
        //string contractName;            // Name of the contract
    }*/

    /* 
     * @dev (FUTURE OPTION) Struct of the Contracts in voting
     */
   /* struct ContractVote {
        address contractAddr;           // Deployed resource contract address
        uint8 contractType;             // Type of the contract (1-ERC20, 2-ERC721, 3-OTHER)
        uint256 sha256Hash;             // Hash of the contract
        uint256 votesYes;               // Total of `YES` votes to deploy a contract
        //string contractName;          // Name of the contract
    }*/
    
    //*********************************************************************************//
    //******************************* PUBLIC FUNCTIONS ********************************//
    //*********************************************************************************//
    /*
     * @dev A public function for adding new Contract to the MagnatGame.
     * @note All new contracts adding after full contract audit. Add function available for C-Level only.
     * @note Available only when Game NOT paused.
     */
    function addContract(
    	address contractAddr,
    	uint8 contractType,
    	string memory contractName
        )
    	public 
        onlyCLevel 
        whenNotPaused 
        returns (uint256){

        // check for array requirements
        require(contractAddr != address(0));
        require(contractType > 0);
        require(bytes(contractName).length > 0);

        // update statement && variables
        uint256 _id = totalContracts++;

        // save data to storage
        contracts[_id] = Contract(
			contractAddr,
			contractType,
			contractName
		);

        validContract[contractAddr] = true;
        idContract[contractAddr] = _id;
    }

    /* 
     * @dev A public function for getting Contracts info contains in the contracts[] array
     */
    function getContract(uint256 _id)
        public view returns (
            address,
            uint8,
            string memory
        ){
        // @dev Need to go with way cause EVM err: `Compiler error: 
        // Stack too deep, try removing local variables.`
        Contract memory c = contracts[_id];
        return (
            c.contractAddr,
            c.contractType,
            c.contractName
        );
    }

    /*
     * @dev A public function to delete contract from the MagnatGame
     * Available for C-Level only. Can bee changed whatever paused the Game or not
     */
    function deleteContract(
        uint256 _id,
        address contractAddr
        )
    	public onlyCLevel returns (bool){

        delete contracts[_id];
        delete validContract[contractAddr];
        totalContracts--;
        return true;
    }

    /*
     * @dev A public function to edit contract info included in the MagnatGame contracts[] array
     * Available for C-Level only. Can bee changed whatever paused the Game or not
     */
    function editContract(
        uint256 _id,
        address contractAddr,
        uint8 contractType,
        string memory contractName
        )
        public 
        onlyCLevel
        returns (uint256){

        // check for array requirements
        require(contractAddr != address(0));
        require(contractType > 0);
        require(bytes(contractName).length > 0);

        // save data to storage
        contracts[_id] = Contract(
            contractAddr,
            contractType,
            contractName
        );
    }
    
    /*
     * @dev Check is a valid Contract or not
     */
    function checkValid(address _contractAddress)
        public view returns(bool){
            return validContract[_contractAddress];
    }

    /*
     * @dev Get Contract ID
     */
    function getContractId(address _contractAddress)
        public view returns(uint256){
            return idContract[_contractAddress];
    }
}