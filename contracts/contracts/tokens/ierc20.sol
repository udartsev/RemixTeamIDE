pragma solidity ^0.5.6;

/**
 * @title ERC20 interface
 * @dev "A standard interface allows any tokens on Ethereum to be re-used by 
 * other applications: from wallets to decentralized exchanges."
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {

	// @dev Optional functions

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

	// @dev Standart Interface functions

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
