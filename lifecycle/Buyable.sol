pragma solidity ^0.4.21;


import "../ownership/Ownable.sol";


/**
 * @title Buyable
 * @dev Base contract which allows children to implement an buy switch mechanism.
 */
contract Buyable is Ownable {
  event Buy(uint256 price);
  event Unbuy();

  // 如果允许用以太币(ETH)兑换本代币, 创建者账号(即owner)可以打开开关(设置为true).
  bool public buy_switch = false; // 买代币在刚部署时是关闭的

  // 以太坊购买代币的价格, 即ETH与本代币的兑换比例.
  uint256 public price;


  /**
   * @dev Modifier to make a function callable only when the contract is not buyable.
   */
  modifier whenNotBuyable() {
    require(!buy_switch);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is buyable.
   */
  modifier whenBuyable() {
    require(buy_switch);
    _;
  }

  /**
   * @dev called by the owner to buy, triggers stopped state
   * @param newPrice 新的价格
   */
  function buy(uint256 newPrice) onlyOwner whenNotBuyable public {
    buy_switch = true;
    price = newPrice;
    emit Buy(newPrice);
  }

  /**
   * @dev called by the owner to unbuy, returns to normal state
   */
  function unbuy() onlyOwner whenBuyable public {
    buy_switch = false;
    emit Unbuy();
  }
}
