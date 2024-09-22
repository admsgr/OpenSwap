 <a href="https://github.com/openswap/Opera/actions/workflows/tests_core.yml"><img alt="Tests status" src="https://github.com/openswap/Opera/actions/workflows/tests_core.yml/badge.svg"></a>
  <a href="https://github.com/openswap/Opera/actions/workflows/echidna_core.yml"><img alt="Echidna status" src="https://github.com/openswap/Opera/actions/workflows/echidna_core.yml/badge.svg"></a>

[![npm](https://img.shields.io/npm/v/@openswap/opera-insider-core?style=flat)](https://npmjs.com/package/@openswap/opera-insider-core)

# Opera

This directory contains the core smart contracts for the Opera DEX. For higher level contracts, see the `periphery` directory.

## License

Licenses for smart contracts are specified in SPDX headers. A key part of the Core contracts is under BUSL-1.1 (Business Source License 1.1).

Most of the interfaces in `./contracts/interfaces` are based on [UniswapV3 core interfaces](https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces) and retain the GPL-2.0 or later license. This is reflected in the appropriate comments in the interface files.

Part of the libraries in `./contracts/libraries` are based on [UniswapV3 core libraries](https://github.com/Uniswap/v3-core/tree/main/contracts/libraries) and retain the GPL-2.0 or later license. This is reflected in the appropriate comments in the libraries files.

