pragma solidity ^0.4.21;

import "./PausableToken.sol";


/**
 * @title Frozenable token
 * @dev PausableToken modified with frozenable transfers.
 * 有时为了监管的需要, 需要实现冻结某些账户. 
 * 冻结后, 其资产仍在账户, 但是不允许交易, 直到解除冻结.
 **/
contract FrozenableToken is PausableToken {
  // 冻结账户
  mapping (address => bool) public frozenAccount;

	/* This generates a public event on the blockchain that will notify clients */
  event FrozenFunds(address target, bool frozen);

  /**
   * @dev `freeze? Prevent | Allow` `target` from sending & receiving tokens
   * @param target Address to be frozen
   * @param freeze either to freeze it or not
   */
  function freezeAccount(address target, bool freeze) onlyOwner public {
  	frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }

  /**
  * @dev 查看某个账号冻结的情况
  * @param _owner The address to query
  * @return freeze or not
  */
  function freezeOf(address _owner) public view returns (bool) {
    return frozenAccount[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!frozenAccount[msg.sender]);  // Check if sender is frozen
    require(!frozenAccount[_to]);         // Check if recipient is frozen
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!frozenAccount[_from]);  // Check if sender is frozen
    require(!frozenAccount[_to]);    // Check if recipient is frozen
    return super.transferFrom(_from, _to, _value);
  }
}
