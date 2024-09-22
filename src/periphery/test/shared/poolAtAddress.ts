import { abi as POOL_ABI } from '@openswap/opera-insider-core/artifacts/contracts/OperaPool.sol/OperaPool.json';
import { Contract, Wallet } from 'ethers';
import { IOperaPool } from '../../typechain';

export default function poolAtAddress(address: string, wallet: Wallet): IOperaPool {
  return new Contract(address, POOL_ABI, wallet) as any as IOperaPool;
}
