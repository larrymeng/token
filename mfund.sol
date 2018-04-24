pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * 来源: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract SafeMath {
	/**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title New ERC23 contract interface (抽象合约)
 */
contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  // function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event LogTransfer(address indexed from, address indexed to, uint value, bytes indexed data);
  // 兼容ERC20的转账事件
  event LogTransferERC20(address indexed from, address indexed to, uint value);
}

/**
 * @title Contract that is working with ERC223 tokens
 * 如果智能合约需要处理接收到的代币, 必须继承本接口且实现tokenFallback函数.
 * 继承时接口名其实不一定与本接口相同, 但函数是必须相同的.
 */
contract ContractReceiver {
  // 抽象类, 作为接口使用.
  function tokenFallback(address from, uint256 value, bytes data) external;
}

/**
 * @title 智能合约
 */
contract MFundToken is ERC223, SafeMath {
  // 每个账号的代币余额, 单位与Wei类似(即10^decimals_个单位代币 == 1个代币).
  mapping(address => uint) balances_;
  
  string public name_;
  string public symbol_;
  uint8 public decimals_ = 18;
  uint256 public totalSupply_;

  // 合约的拥有者
  address private owner_;
  // 奖励(挖矿)的账号
  address private reward_addr_;
  // 初创团队的账号
  address private founder_team_addr_;
  // 投资者的账号
  address private investor_addr_;
  // 顾问账号
  address private advisor_addr_;

  // 如果发生紧急情况, 创建者账号可以停止交易(设置为true).
  bool public halted_ = true; // 刚部署时是不允许交易的
  // 以太坊购买代币的价格
  uint public price_;
  // 购买代币默认情况是关闭的
  bool public buy_switch_ = false;

  // 日志(事件)
  event LogExchangeETH(address indexed to, uint token_num, uint value);
  event LogBuyToken(uint token_num, uint value);

  /**
   * @dev 构造函数
   *
   * @param tokenName     代币的名称
   * @param tokenSymbol   代币的符号
   * @param reward_addr       奖励(挖矿)的账号
   * @param founder_team_addr 初创团队的账号
   * @param investor_addr     投资者的账号
   * @param reward_supply       分配给奖励(挖矿)的代币数量
   * @param founder_team_supply 分配给初创团队的代币数量
   * @param investor_supply     分配给投资者的代币数量
   * @param owner_supply        分配给合约拥有者的代币数量
   *
   * @return None
   */
  function MFundToken(string tokenName, string tokenSymbol,
             address reward_addr,   address founder_team_addr,   address investor_addr,   address advisor_addr,
             uint256 reward_supply, uint256 founder_team_supply, uint256 investor_supply, uint256 advisor_supply,
             uint256 owner_supply) public {
    name_   = tokenName;
    symbol_ = tokenSymbol;

    owner_             = msg.sender;
    reward_addr_       = reward_addr;
    founder_team_addr_ = founder_team_addr;
    investor_addr_     = investor_addr;
    advisor_addr_      = advisor_addr;

    balances_[reward_addr_]       = reward_supply * 10 ** uint256(decimals_);
    balances_[founder_team_addr_] = founder_team_supply * 10 ** uint256(decimals_);
    balances_[investor_addr_]     = investor_supply * 10 ** uint256(decimals_);
    balances_[advisor_addr_]      = advisor_supply * 10 ** uint256(decimals_);
    balances_[owner_]             = owner_supply * 10 ** uint256(decimals_);
    totalSupply_ = safeAdd(balances_[reward_addr_], balances_[founder_team_addr_]);
    totalSupply_ = safeAdd(totalSupply_, balances_[investor_addr_]);
    totalSupply_ = safeAdd(totalSupply_, balances_[advisor_addr_]);
    totalSupply_ = safeAdd(totalSupply_, balances_[owner_]);
  }

  /**
   * @dev 停止交易
   */
  function halt() public {
    // 只有 合约的拥有者 才能操作
    if(msg.sender != owner_) revert();
    halted_ = true;
  }
  /**
   * @dev 启动交易
   */
  function unhalt() public {
    // 只有 合约的拥有者 才能操作
    if(msg.sender != owner_) revert();
    halted_ = false;
  }

  /**
   * @dev 打开购买代币的开关
   * @param price 设置的价格 
   */
  function turnOnBuy(uint price) public {
    // 只有 合约的拥有者 才能操作
    if(msg.sender != owner_) revert();
    buy_switch_ = true;
    price_ = price;
  }
  /**
   * @dev 关闭购买代币的开关
   */
  function turnOffBuy() public {
    // 只有 合约的拥有者 才能操作
    if(msg.sender != owner_) revert();
    buy_switch_ = false;
  }


  /**
   * @dev 代币兑换以太币
   *
   * @param to        要兑换的用户地址
   * @param token_num 要兑换的代币数目
   *
   * @return success 成功与否
   */
  function exchangeETH(address to, uint token_num) public payable returns (bool success) {
    // 交易已停止
    if(halted_) revert();

    // 只有 奖励(挖矿)的账号 能操作
    if(msg.sender != reward_addr_) revert();
    // to不能是合约地址
    if(isContract(to)) revert();
    // 检查用户的代币是否足够
    if(balanceOf(to) < token_num) revert();

    // 将代币从to地址转到当前地址:
    // 1) to的余额做减法
    balances_[to] = safeSub(balanceOf(to), token_num);
    // 2) 当前地址的余额做加法
    balances_[msg.sender] = safeAdd(balanceOf(msg.sender), token_num);

    // 向to地址转入以太币(单位是wei)
    to.transfer(msg.value);
    // 事件(日志)
    LogExchangeETH(to, token_num, msg.value);
    return true;
  }

  /**
   * @dev 以太币兑换代币
   *
   * @return success 成功与否
   */
  function buyToken() public payable returns (bool success) {
    // 交易已停止(双重开关)
    if(halted_ || !buy_switch_) revert();

    // 买到的代币数量
    uint token_num = safeMul(msg.value, price_);
    // 检查代币数量是否足够
    if(balanceOf(owner_) < token_num) revert();

    // 代币转移: owner_ -> msg.sender

    // 向合约拥有者地址转入以太币(单位是wei)
    // 地址无效或者合约发起方余额不足时, 代码将抛出异常并停止转账.
    // 防止: gas限制 / 调用栈调用深度的限制
    owner_.transfer(msg.value);

    // 减少owner的代币
    balances_[owner_]     = safeSub(balanceOf(owner_), token_num);

    // 最后才增加发起者的代币
    balances_[msg.sender] = safeAdd(balanceOf(msg.sender), token_num);

    // 事件(日志)
    LogBuyToken(token_num, msg.value);
    return true;
  }

  // // Function that is called when a user or another contract wants to transfer funds .
  // function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool success) {
  //   // 交易已停止
  //   if(halted_) revert();

  //   // to是合约地址
  //   if(isContract(to)) {
  //     // 如果当前的余额不够就抛出异常.
  //     // 从0.4.13版本, throw关键字已被弃用, 将来会被淘汰, 用revert()替代.
  //     if (balanceOf(msg.sender) < value) revert();
  //     // 发送者的余额做减法
  //     balances_[msg.sender] = safeSub(balanceOf(msg.sender), value);
  //     // 接收者的余额做加法
  //     balances_[to] = safeAdd(balanceOf(to), value);
  //     // 初始化接收合约, 构造函数参数为接收者的合约地址.
  //     assert(to.call.value(0)(bytes4(keccak256(custom_fallback)), msg.sender, value, data));
  //     // 事件
  //     LogTransfer(msg.sender, to, value, data);
  //     return true;
  //   }
  //   else { // to是用户地址
  //     return transferToAddress(to, value, data);
  //   }
  // }
  
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address to, uint value, bytes data) public returns (bool success) {
    // 交易已停止
    if(halted_) revert();

    if(isContract(to)) {
      return transferToContract(to, value, data);
    }
    else {
      return transferToAddress(to, value, data);
    }
  }
  
  // 类似于ERC20传输的标准功能传输, 没有data.
  // 由于向后兼容性原因而增加.
  // Standard function transfer similar to ERC20 transfer with no data .
  // Added due to backwards compatibility reasons .
  function transfer(address to, uint value) public returns (bool success) {
    // 交易已停止
    if(halted_) revert();

    // standard function transfer similar to ERC20 transfer with no data
    // added due to backwards compatibility reasons
    bytes memory empty;
    if(isContract(to)) {
      return transferToContract(to, value, empty);
    }
    else {
      return transferToAddress(to, value, empty);
    }
  }

  // assemble the given address bytecode. If bytecode exists then the addr is a contract.
  function isContract(address addr) private view returns (bool is_contract) {
    uint length;
    assembly {
      // 检索目标地址上的代码大小, 这需要汇编.
      // retrieve the size of the code on target address, this needs assembly
      length := extcodesize(addr)
    }
    return (length>0);
  }

  // function that is called when transaction target is an address
  function transferToAddress(address to, uint value, bytes data) private returns (bool success) {
    if (balanceOf(msg.sender) < value) revert();
    balances_[msg.sender] = safeSub(balanceOf(msg.sender), value);
    balances_[to] = safeAdd(balanceOf(to), value);
    if(0 == data.length){
      LogTransferERC20(msg.sender, to, value);
    }else {
      LogTransfer(msg.sender, to, value, data);
    }
    return true;
  }
  
  // function that is called when transaction target is a contract
  function transferToContract(address to, uint value, bytes data) private returns (bool success) {
    if (balanceOf(msg.sender) < value) revert();
    balances_[msg.sender] = safeSub(balanceOf(msg.sender), value);
    balances_[to] = safeAdd(balanceOf(to), value);

    // 初始化接收合约, 构造函数参数为目标合约地址.
    // When you do ContractX x = ContractX(contract's Address) 
    // you are instantiating an existing contract at the address specified. 
    // If you know its functions you may call them from another contract. 
    // 部署到网络上后, 它们是两个完全独立的合约.
    // 解释: 
    // You are not intantiating a new contract on the address of to. 
    // You are only specifiying that contract can be found there if it is implemented.
    // we are only assuming at the address to there is a contract(or interface 
    // implementation) called ContractReceiver
    ContractReceiver receiver = ContractReceiver(to);
    // 解释:
    // and now we are assuming that such contract at to has tokenFallback function
    // but if such function or such contract does not exist at such address, we get failure... then what?
    // In Solidity, transactions are called atomic, that means either the entire 
    // transaction all succeed together, or all fail together. So even if there 
    // is one line( receiver.tokenFallback() ) in the function fails, the entire 
    // function will fail all together. Then the balances will be restored to 
    // their original values. 
    // Solved for ERC223 tokens transfer to contract not compatible fail error/failure
    receiver.tokenFallback(msg.sender, value, data);
    if(0 == data.length){
      LogTransferERC20(msg.sender, to, value);
    }else {
      LogTransfer(msg.sender, to, value, data);
    }
    return true;
  }

  /**
   * @dev Returns balance of the `owner`.
   *
   * @param owner   The address whose balance will be returned.
   * @return balance Balance of the `owner`.
   */
  function balanceOf(address owner) public view returns (uint balance) {
    return balances_[owner];
  }
}
