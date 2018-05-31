pragma solidity ^0.4.21;

import "./Ownable.sol";
import "../token/ERC20Basic.sol";
import "../token/SafeERC20.sol";


/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 * 用途: I think it will be great to allow some smart contracts to recover tokens, mistakenly sent to them. 
 * For example, some people send tokens to the token smart contracts directly, 
 * or to smart contracts that just do not support any tokens handling.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }
}
