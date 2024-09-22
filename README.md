<p align="center">
  <a href="https://openswap.fi/"><img alt="Opera" src="logo.svg" width="360"></a>
</p>

<p align="center">
Innovative DEX with concentrated liquidity and customizable plugins.
</p>
 
<p align="center">
<a href="https://github.com/openswap/Opera/actions/workflows/tests_core.yml"><img alt="Tests status" src="https://github.com/openswap/Opera/actions/workflows/tests_core.yml/badge.svg"></a>
<a href="https://github.com/openswap/Opera/actions/workflows/tests_periphery.yml"><img alt="Echidna status" src="https://github.com/openswap/Opera/actions/workflows/tests_periphery.yml/badge.svg"></a>
<a href="https://github.com/openswap/Opera/actions/workflows/tests_plugin.yml"><img alt="Tests status" src="https://github.com/openswap/Opera/actions/workflows/tests_plugin.yml/badge.svg"></a>
<a href="https://github.com/openswap/Opera/actions/workflows/tests_farmings.yml"><img alt="Tests status" src="https://github.com/openswap/Opera/actions/workflows/tests_farmings.yml/badge.svg"></a>
</p>
<p align="center">
<a href="https://github.com/openswap/Opera/actions/workflows/echidna_core.yml"><img alt="Echidna status" src="https://github.com/openswap/Opera/actions/workflows/echidna_core.yml/badge.svg"></a>
<a href="https://github.com/openswap/Opera/actions/workflows/echidna_periphery.yml"><img alt="Echidna status" src="https://github.com/openswap/Opera/actions/workflows/echidna_periphery.yml/badge.svg"></a>
<a href="https://github.com/openswap/Opera/actions/workflows/echidna_plugin.yml"><img alt="Echidna status" src="https://github.com/openswap/Opera/actions/workflows/echidna_plugin.yml/badge.svg"></a>
<a href="https://github.com/openswap/Opera/actions/workflows/echidna_farming.yml"><img alt="Echidna status" src="https://github.com/openswap/Opera/actions/workflows/echidna_farming.yml/badge.svg"></a>
</p>


- [Docs](#docs)
- [Versions](#versions)
- [Packages](#packages)
- [Build](#build)
- [Tests](#tests)
- [Tests coverage](#tests-coverage)
- [Deploy](#deploy)

## Docs

The documentation page is located at: [https://docs.openswap.fi/](https://docs.openswap.fi/)

## Versions

Please note that different DEX-partners of our protocol may use different versions of the protocol. This repo contains the latest version: **Opera Insider**. 

A page describing the versions used by partners can be found in the documentation: [partners page](https://docs-v1.openswap.fi/en/docs/contracts/partners/introduction)

Previous versions of the protocol have been moved to separate repositories:

[Opera V1.9](https://github.com/openswap/OperaV1.9)

[Opera V1](https://github.com/openswap/OperaV1)

## Packages

Core: [https://www.npmjs.com/package/@openswap/opera-insider-core](https://www.npmjs.com/package/@openswap/opera-insider-core)

Periphery: [https://www.npmjs.com/package/@openswap/opera-insider-periphery](https://www.npmjs.com/package/@openswap/opera-insider-periphery)

Farming: [https://www.npmjs.com/package/@openswap/opera-insider-farming](https://www.npmjs.com/package/@openswap/opera-insider-farming)

Basic plugin: [https://www.npmjs.com/package/@openswap/opera-insider-base-plugin](https://www.npmjs.com/package/@openswap/opera-insider-base-plugin)

## Build

*Requires npm >= 8.0.0*

To install dependencies, you need to run the command in the root directory:
```
$ npm run bootstrap
```
This will download and install dependencies for all modules and set up husky hooks.



To compile a specific module, you need to run the following command in the module folder:
```
$ npm run compile
```


## Tests

Tests for a specific module are run by the following command in the module folder:
```
$ npm run test
```

## Tests coverage

To get a test coverage for specific module, you need to run the following command in the module folder:

```
$ npm run coverage
```

## Deploy
Firstly you need to create `.env` file in the root directory of project as in `env.example`.

To deploy all modules in specific network:
```
$ node scripts/deployAll.js <network>
```
