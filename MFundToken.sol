pragma solidity ^0.4.21;

import "./token/PausableToken.sol";
import "./ownership/HasNoTokens.sol";
import "./ownership/Rewardable.sol";
import "./lifecycle/Buyable.sol";
import "./math/SafeMath.sol";

/**
 * @title 智能合约
 */
contract MFundToken is PausableToken,HasNoTokens,Rewardable,Buyable {
  using SafeMath for uint256;

	string public constant name     = "mFund";
  string public constant symbol   = "mFund";
  uint8  public constant decimals = 18;

  // 初创团队的账号
  address public founderAddr;
  // 投资者的账号
  address public investorAddr;
  // 顾问账号
  address public advisorAddr;

  // 总共发行8亿个币
  uint256 public constant INITIAL_SUPPLY  = 800000000 * (10 ** uint256(decimals));
  // 代币的分配
  uint256 public constant OWNER_SUPPLY    = 100000000 * (10 ** uint256(decimals));
  uint256 public constant REWARD_SUPPLY   = 200000000 * (10 ** uint256(decimals));
  uint256 public constant FOUNDER_SUPPLY  = 100000000 * (10 ** uint256(decimals));
  uint256 public constant INVESTOR_SUPPLY = 300000000 * (10 ** uint256(decimals));
  uint256 public constant ADVISOR_SUPPLY  = 100000000 * (10 ** uint256(decimals));

  // 日志(事件)
  event ExchangeETH(address indexed to, uint256 tokenNum, uint256 value);
  event BuyToken(uint tokenNum, uint256 value);


  /**
   * @dev 构造函数
   * @param _rewardAddr  地址
   * @param _founderAddr 地址
   * @param _investorAddr 地址
   * @param _advisorAddr 地址
   */
  function MFundToken(address _rewardAddr,   address _founderAddr, 
                      address _investorAddr, address _advisorAddr) public {
    owner = msg.sender;  

    rewardAddr   =  _rewardAddr;
    founderAddr  = _founderAddr;
    investorAddr = _investorAddr;
    advisorAddr  = _advisorAddr;

    balances[owner]        = OWNER_SUPPLY;
    balances[rewardAddr]   = REWARD_SUPPLY;
    balances[founderAddr]  = FOUNDER_SUPPLY;
    balances[investorAddr] = INVESTOR_SUPPLY;
    balances[advisorAddr]  = ADVISOR_SUPPLY;

    totalSupply_ = INITIAL_SUPPLY;
  }

  /**
   * @dev 代币兑换以太币 
   * 目标地址的代币转移到reward_addr上, 而reward_addr则发送ETH到目标地址上.
   * 只能由reward_addr调用!
   * @param to 要兑换的用户钱包地址
   * @param tokenNum 目标地址需要消耗的代币数目(注意单位!)
   */
  function exchangeETH(address to, uint256 tokenNum)
    payable
    whenNotPaused
    onlyRewardable
    public
    returns (bool)
  {
    // 目标地址不能为空
    require(to != address(0));

    // token转账: to -> reward_addr
    require(tokenNum <= balances[to]);
    balances[to] = balances[to].sub(tokenNum);
    balances[rewardAddr] = balances[rewardAddr].add(tokenNum);

    // 向目标地址发送以太币(单位是wei)
    to.transfer(msg.value);

    // 事件(日志)
    emit ExchangeETH(to, tokenNum, msg.value);
    return true;
  }

  /**
   * @dev 以太币兑换代币
   * 任何人都可以用ETH购买本代币, 即与owner交换.
   */
  function buyToken()
    payable
    whenNotPaused
    whenBuyable
    public
    returns (bool)
  {
    // 买到的代币数量
    uint256 tokenNum = msg.value.mul(price);
    // 检查代币owner数量是否足够
    require(tokenNum <= balances[owner]);

    // 代币转移: owner -> msg.sender
    // 址无效或者合约发起方余额不足时, 代码将抛出异常并停止转账.
    owner.transfer(msg.value); 
    // 减少owner的代币
    balances[owner] = balances[owner].sub(tokenNum);
    // 最后才增加发起者的代币
    balances[msg.sender] = balances[msg.sender].add(tokenNum);

    // 事件(日志)
    emit BuyToken(tokenNum, msg.value);
    return true;
	}
}
