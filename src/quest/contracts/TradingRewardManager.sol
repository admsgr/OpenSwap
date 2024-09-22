// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IQuest.sol';

contract TradingRewardManager is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  struct QuestInfo {
    address questContract;
    uint256 allocPoint;
    uint256 lastRewardBlock;
    uint256 accPerShare;
  }
  QuestInfo[] public questInfo;
  // Total allocation poitns. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;

  function questLength() external view returns (uint256) {
    return questInfo.length;
  }

  modifier checkQuestExist(address _qAddress) {
    for (uint i = 0; i < questInfo.length; ++i) {
      require(questInfo[i].questContract != _qAddress, 'Quest Exist');
    }
    _;
  }

  function addQuest(uint256 _allocPoint, address _qAddress, bool _withUpdate) public onlyOwner checkQuestExist(_qAddress) {
    questInfo.push(QuestInfo({questContract: _qAddress, allocPoint: _allocPoint, lastRewardBlock: block.timestamp, accPerShare: 0}));
  }

  function setQuest(uint256 _qid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
    totalAllocPoint = totalAllocPoint.sub(questInfo[_qid].allocPoint).add(_allocPoint);
    questInfo[_qid].allocPoint = _allocPoint;
  }

  function removeQuest(uint256 _qid, bool _withUpdate) public onlyOwner {
    totalAllocPoint = totalAllocPoint.sub(questInfo[_qid].allocPoint);
    questInfo[_qid] = questInfo[questInfo.length - 1];
    questInfo.pop();
    uint256 sumAllocPoint = 0;
    for (uint256 i = 0; i <= questInfo.length; i++) {
      sumAllocPoint += questInfo[i].allocPoint;
    }
    require(sumAllocPoint == totalAllocPoint, 'AllocPoint NOT Match');
  }

  function enterQuest(uint256 _qid) public {
    IQuest(questInfo[_qid].questContract).register();
  }

  function claimQuest(uint256 _qid) public {
    IQuest(questInfo[_qid].questContract).claimReward();
  }
}
