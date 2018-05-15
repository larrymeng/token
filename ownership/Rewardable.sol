pragma solidity ^0.4.21;

import "./Ownable.sol";

/**
 * @title 奖励(挖矿)账号相关操作
 */
contract Rewardable is Ownable {
  // 奖励(挖矿)的账号
  address public rewardAddr;

  // 日志(事件)
  event RewardshipTransferred(address indexed previousRewardAddr, address indexed newRewardAddr);

  /**
   * @dev Throws if called by any account other than the rewardAddr.
   */
  modifier onlyRewardable() {
    // 只有 奖励(挖矿)账号 才能操作
    require(msg.sender == rewardAddr);
    _;
  }

  /**
   * @dev Allows the current rewardAddr to transfer control of rewarding to a newRewardAddr.
   * 只有owner能操作!
   * @param _newRewardAddr The address to transfer rewarding to.
   */
  function transferRewardship(address _newRewardAddr) onlyOwner public {
    require(_newRewardAddr != address(0));
    emit RewardshipTransferred(rewardAddr, _newRewardAddr);
    rewardAddr = _newRewardAddr;
  }
}
