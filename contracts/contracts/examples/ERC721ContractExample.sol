pragma solidity ^0.5.6;

import "./tokens/nf-token-metadata.sol";
import "./ownership/ownable.sol";
import "./access/access-control.sol";

/**
 * @dev This is an example contract implementation of NFToken with metadata extension.
 * Based on ERC-721 Token — Reference Implementation by 0xcert
 * see: https://github.com/0xcert/ethereum-erc721
 */
contract ERC721ContractExample is
  NFTokenMetadata,
  Ownable,
  AccessControl
{

  /**
   * @dev Contract constructor. Sets metadata extension `name` and `symbol`. 
   */
  constructor(string memory tokenName, string memory tokenSymol)
    public
    //onlyCOO
  {
    nftName = tokenName;
    nftSymbol = tokenSymol;
  }

  /**
   * @dev Mints a new NFT.
   * @param _to The address that will own the minted NFT.
   * @param _tokenId of the NFT to be minted by the msg.sender.
   * @param _uri String representing RFC 3986 URI.
   */
  function mint(
    address _to,
    uint256 _tokenId,
    string calldata _uri
  )
    external
    //onlyCOO
  {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
}
