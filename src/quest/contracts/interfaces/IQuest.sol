// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuest {
  function register() external returns (uint256);

  function claimReward() external returns (uint256);
}
