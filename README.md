# Surge
Surge is a highly experimental, self-custody Lightning wallet built to work for iOS and macOS.

## Motivation
Tools and infrastructure for running a non-custodial Lightning wallet is advancing fast. Surge aims to be a project that developers can reference for "recipes" on how to implement a Lightning wallet with [Lightning Development Kit](https://github.com/lightningdevkit/rust-lightning/).

This project will strive and do its best in demonstrating idioms for implementation on Apple platforms. It includes things like properly handling `lightning://` URIs to encrypting and persisting channel material on-disk.

Therefore, if you see something that looks like bad Swift code, please file an issue! :) 

## Support
Surge currently is aiming to support the following environments/setups:
- Regtest (with Polar)
- Testnet w/ Bitcoin Core
- Testnet w/ Electrum

## License
See [LICENSE.md](https://github.com/jurvis/Surge/blob/main/LICENSE.md)
