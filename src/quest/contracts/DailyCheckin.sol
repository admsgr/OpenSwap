// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 {
  function mint(address user, uint256 token, uint256 amount) external;
}

contract DailyReward {
  int256 constant OFFSET19700101 = 2440588;
  uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint8 constant BITCOIN_GIFT_BOX = 3;
  uint8 constant ETHEREUM_GIFT_BOX = 2;
  uint8 constant STABLECOIN_GIFT_BOX = 1;
  struct Player {
    uint8 giftBox;
    uint8 contCheckin;
    uint256 rewardToken;
    uint256 lastCheckinTimestamp;
  }
  mapping(address => Player) public players;
  address public rewardManager;
  uint256 baseReward;

  constructor(address _rewardManager, uint256 _baseReward) {
    baseReward = _baseReward;
    rewardManager = _rewardManager;
  }

  modifier isCheckin(address _user) {
    bool result = _getCheckinStatus(_user);
    require(result, 'Already Checked-in today');
    _;
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
    unchecked {
      int256 __days = int256(_days);
      int256 L = __days + 68569 + OFFSET19700101;
      int256 N = (4 * L) / 146097;
      L = L - (146097 * N + 3) / 4;
      int256 _year = (4000 * (L + 1)) / 1461001;
      L = L - (1461 * _year) / 4 + 31;
      int256 _month = (80 * L) / 2447;
      int256 _day = L - (2447 * _month) / 80;
      L = _month / 11;
      _month = _month + 2 - 12 * L;
      _year = 100 * (N - 49) + _year + L;
      year = uint256(_year);
      month = uint256(_month);
      day = uint256(_day);
    }
  }

  function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
    unchecked {
      (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
  }

  function _firstCheckin(address _user) internal {
    Player storage _p = players[_user];
    _p.giftBox = 0;
    _p.contCheckin = 1;
    _p.rewardToken = baseReward;
    _p.lastCheckinTimestamp = block.timestamp;
  }

  function _isContinuousCheckin(address _user) internal view returns (bool) {
    Player memory _p = players[_user];
    uint256 _nextCheckinTimestamp = _p.lastCheckinTimestamp + SECONDS_PER_DAY;
    (uint256 year1, uint256 month1, uint256 day1) = timestampToDate(_nextCheckinTimestamp);
    (uint256 year2, uint256 month2, uint256 day2) = timestampToDate(block.timestamp);
    if (year2 == year1 && month2 == month1 && day2 == day1) return true;
    return false;
  }

  function _getCheckinStatus(address _user) internal view returns (bool) {
    Player storage _p = players[_user];
    uint256 _lastCheckinTimestamp = _p.lastCheckinTimestamp;
    if (_lastCheckinTimestamp == 0) return true;
    (uint256 year1, uint256 month1, uint256 day1) = timestampToDate(_lastCheckinTimestamp);
    (uint256 year2, uint256 month2, uint256 day2) = timestampToDate(block.timestamp);
    if (year1 == year2 && month1 == month2 && day1 == day2) return false;
    return true;
  }

  function getCheckinStatus(address _user) external view returns (bool) {
    return _getCheckinStatus(_user);
  }

  function register() public isCheckin(msg.sender) returns (uint256) {
    Player storage _p = players[msg.sender];
    if (!_isContinuousCheckin(msg.sender)) {
      _firstCheckin(msg.sender);
      return baseReward;
    }
    uint8 _checkin = _p.contCheckin;
    if (_checkin == 0) {
      IERC1155(rewardManager).mint(msg.sender, BITCOIN_GIFT_BOX, 1);
      _firstCheckin(msg.sender);
      return baseReward;
    }
    if (_checkin == 6) {
      IERC1155(rewardManager).mint(msg.sender, ETHEREUM_GIFT_BOX, 1);
      _p.lastCheckinTimestamp = block.timestamp;
      _p.rewardToken += baseReward + _p.contCheckin * (baseReward / 5);
      _p.giftBox = BITCOIN_GIFT_BOX;
      _p.contCheckin = 0;
      return _p.rewardToken;
    }
    if (_checkin == 5) {
      IERC1155(rewardManager).mint(msg.sender, STABLECOIN_GIFT_BOX, 1);
      _p.lastCheckinTimestamp = block.timestamp;
      _p.contCheckin++;
      _p.rewardToken += baseReward + _p.contCheckin * (baseReward / 5);
      _p.giftBox = ETHEREUM_GIFT_BOX;
      return _p.rewardToken;
    }
    if (_checkin == 4) {
      _p.lastCheckinTimestamp = block.timestamp;
      _p.contCheckin++;
      _p.rewardToken += baseReward + _p.contCheckin * (baseReward / 5);
      _p.giftBox = STABLECOIN_GIFT_BOX;
      return _p.rewardToken;
    }
    _p.lastCheckinTimestamp = block.timestamp;
    _p.contCheckin++;
    _p.rewardToken += baseReward + _p.contCheckin * (baseReward / 5);
    _p.giftBox = 0;
    return _p.rewardToken;
  }

  function claimReward() public returns (uint256 rewards) {
    Player storage _p = players[msg.sender];
    require(_p.lastCheckinTimestamp != 0, 'Player not registered');
    rewards = _p.rewardToken; // Reset the player's reward and update the last claimed time
    _p.rewardToken = 0;
  }
}
