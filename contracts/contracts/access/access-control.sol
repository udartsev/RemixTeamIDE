pragma solidity ^0.5.6;

// @title AccessControl contract that manages special access privileges.
// @note It is a part of MagnatBase contract. So, if you want to use AccessControl functions
// just use MagnatBase Contract symlink in your code.
contract AccessControl {
    // This facet controls access control. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the Core constructor.
    //
    //     - The CFO: The CFO can withdraw funds from Core and its auction contracts.
    //
    //     - The COO: The COO can release new contracts to auction, and mint promo contracts.
    //
    //     - The ROBOT: Thre ROBOT can change variables automatically for better game balance.
    //          It turned of by default and will be enabled when game will need it.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn't have the ability to act in those roles. This
    // restriction is intentional so that we aren't tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    /************************************************************************************************/
    /************************************** STATEMENTS **********************************************/
    /************************************************************************************************/
    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address public robotAddress;

    // New SEO address. Uses for Game Rights transfer protection.
    address public newCEOAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked.
    // @note If `pause` = `true`, all ethereum payable transactions will be stoped
    bool public paused = false;

    /************************************************************************************************/
    /*************************************** MODIFIERS **********************************************/
    /************************************************************************************************/
    // @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    // @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    // @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }
    
    // @dev Access modifier for C-level-only functionality
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == cooAddress ||
            msg.sender == robotAddress
        );
        _;
    }

    // @dev Access modifier for D-level-only functionality
    modifier onlyDLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == robotAddress
        );
        _;
    }

    // @dev Access modifier for ROBOT-only functionality
    modifier onlyROBOT() {
        require(msg.sender == robotAddress);
        _;
    }

    /********************************************************/
    /*** Pausable functionality adapted from OpenZeppelin ***/
    /********************************************************/

    // @dev Access modifier for C-level-only functionality
    modifier Pausable() {
        require(!paused);
        _;
    }

    // @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    // @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }
    /************************************************************************************************/
    /************************************ EXTERNAL FUNCTIONS ****************************************/
    /************************************************************************************************/
    
    // @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    // Uses newCEOAddress statement for a foolproof protection.
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        if (_newCEO != newCEOAddress) {
            newCEOAddress = _newCEO;
        } else {
            ceoAddress = _newCEO;
        }
    }

    // @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

    // @dev Assigns a new address to act as the COO. Only available to the current CEO.
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }

    // @dev Assigns a new address to act as the COO. Only available to the current CEO.
    function setROBOT(address _newROBOT) external onlyCEO {
        require(_newROBOT != address(0));
        robotAddress = _newROBOT;
    }

    // @dev Called by any "C-level" role to pause the contract. Used only when
    //  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }
    
    /************************************************************************************************/
    /************************************** PUBLIC FUNCTIONS ****************************************/
    /************************************************************************************************/
    // @dev Access check for C-level-only functionality
    function checkCEOLevel(address _address) 
        public view returns(bool) {
        if (_address == ceoAddress) {return true;} 
        else {return false;}
    }
    
    // @dev Access check for C-level-only functionality
    function checkCLevel(address _address) 
        public view returns(bool) {
        if (
            _address == ceoAddress ||
            _address == cfoAddress ||
            _address == cooAddress ||
            _address == robotAddress
        ) {return true;} 
        else {return false;}
    }
    
    // @dev Check for a game not paused
    function checkNotPaused() 
        public view returns(bool) {
        if (paused != true) {return true;} else {return false;}
    }
    
    // @dev Unpauses the smart contract. Can only be called by the CEO, since
    //  one reason we may pause the contract is when CFO or COO accounts are
    //  compromised.
    // @notice This is public rather than external so it can be called by
    //  derived contracts.
    function unpause() public onlyCEO whenPaused {
        // can't unpause if contract was upgraded
        paused = false;
    }
    
    

}
