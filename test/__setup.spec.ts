
import { expect } from 'chai';
import { Signer, ZeroAddress } from 'ethers';
import { ethers, upgrades } from 'hardhat';
import {
  X404Hub__factory,
  X404Hub,
  Events,
  Events__factory
} from '../typechain-types';
import {
  revertToSnapshot,
  takeSnapshot
} from './helpers/utils';
import { ERRORS } from './helpers/errors';

export let accounts: Signer[];
export let deployer: Signer;
export let owner: Signer;
export let user: Signer;
export let userTwo: Signer;
export let deployerAddress: string;
export let ownerAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let x404Hub: X404Hub;
export let eventsLib: Events;

export const decimals = 18;

export function makeSuiteCleanRoom(name: string, tests: () => void) {
  describe(name, () => {
    beforeEach(async function () {
      await takeSnapshot();
    });
    tests();
    afterEach(async function () {
      await revertToSnapshot();
    });
  });
}

before(async function () {
  accounts = await ethers.getSigners();
  deployer = accounts[0];
  owner = accounts[3];
  user = accounts[1];
  userTwo = accounts[2];

  deployerAddress = await deployer.getAddress();
  userAddress = await user.getAddress();
  userTwoAddress = await userTwo.getAddress();
  ownerAddress = await owner.getAddress();

  const swapRouterArray = [
    {
      bV2orV3: true,
      routerAddr: '0x3512ebD0Eb455f2FFDE4908D24F64aba7995951C',
      uniswapV3NonfungiblePositionManager: ZeroAddress,
    },
  ];
  
  const X404Hub = await ethers.getContractFactory("X404Hub");
  const proxy = await upgrades.deployProxy(X404Hub, [deployerAddress, 24 * 60 * 60, swapRouterArray]);
  const proxyAddress = await proxy.getAddress()
  console.log("proxy address: ", proxyAddress)
  console.log("admin address: ", await upgrades.erc1967.getAdminAddress(proxyAddress))
  console.log("implement address: ", await upgrades.erc1967.getImplementationAddress(proxyAddress))
  x404Hub = X404Hub__factory.connect(proxyAddress)
  await expect(x404Hub.connect(owner).SetBlueChipNftContract([ownerAddress], true)).to.be.reverted
  await expect(x404Hub.connect(owner).setSwapRouter([])).to.be.reverted
  await expect(x404Hub.connect(owner).setNewRedeemDeadline(10000)).to.be.reverted
  await expect(x404Hub.connect(owner).setContractURI(ownerAddress, "as")).to.be.reverted
  await expect(x404Hub.connect(owner).setTokenURI(ownerAddress, "asd")).to.be.reverted


  eventsLib = await new Events__factory(deployer).deploy();
});
