pragma solidity ^0.4.21;

import "./FrozenableToken.sol";
import "../math/SafeMath.sol";


/**
 * @title 代币增发
 **/
contract MintToken is FrozenableToken {
  using SafeMath for uint256;

  /**
   * @dev Create `mintedAmount` tokens and send it to owner
   * @param mintedAmount the amount of tokens it will receive
   */
  function mintToken(uint256 mintedAmount) onlyOwner public {
    balances[owner] = balances[owner].add(mintedAmount);
    totalSupply_ = totalSupply_.add(mintedAmount);
    emit Transfer(0, owner, mintedAmount);
  }
}
