// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import '../base/OperaFeeConfiguration.sol';
import '../libraries/AdaptiveFee.sol';

import '@openswap/opera-insider-core/contracts/libraries/Constants.sol';

contract AdaptiveFeeTest {
  using OperaFeeConfigurationU144Lib for OperaFeeConfiguration;

  OperaFeeConfiguration public feeConfig;

  constructor() {
    feeConfig = AdaptiveFee.initialFeeConfiguration();
  }

  function getFee(uint88 volatility) external view returns (uint256 fee) {
    return AdaptiveFee.getFee(volatility, feeConfig.pack());
  }

  function getGasCostOfGetFee(uint88 volatility) external view returns (uint256) {
    OperaFeeConfigurationU144 _packed = feeConfig.pack();
    unchecked {
      uint256 gasBefore = gasleft();
      AdaptiveFee.getFee(volatility, _packed);
      return gasBefore - gasleft();
    }
  }

  function packAndUnpackFeeConfig(OperaFeeConfiguration calldata config) external pure returns (OperaFeeConfiguration memory unpacked) {
    OperaFeeConfigurationU144 _packed = OperaFeeConfigurationU144Lib.pack(config);
    unpacked.alpha1 = _packed.alpha1();
    unpacked.alpha2 = _packed.alpha2();
    unpacked.beta1 = _packed.beta1();
    unpacked.beta2 = _packed.beta2();
    unpacked.gamma1 = _packed.gamma1();
    unpacked.gamma2 = _packed.gamma2();
    unpacked.baseFee = _packed.baseFee();
  }
}
