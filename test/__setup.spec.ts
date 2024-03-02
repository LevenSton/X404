
import { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';
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

  x404Hub = await new X404Hub__factory(deployer).deploy();
  await expect(x404Hub.connect(owner).SetBlueChipNftContract([ownerAddress], true)).to.be.reverted
  await expect(x404Hub.connect(owner).setSwapRouter([])).to.be.reverted
  await expect(x404Hub.connect(owner).setNewRedeemDeadline(10000)).to.be.reverted
  await expect(x404Hub.connect(owner).setContractURI(ownerAddress, "as")).to.be.reverted
  await expect(x404Hub.connect(owner).setTokenURI(ownerAddress, "asd")).to.be.reverted

  const paramArr = {
    bV2orV3: true,
    routerAddr: "0x3512ebD0Eb455f2FFDE4908D24F64aba7995951C",
    uniswapV3NonfungiblePositionManager: ""
  }
  await expect(x404Hub.connect(deployer).initialize(deployerAddress, 24 * 60 * 60, [])).to.not.be.reverted

  expect(x404Hub).to.not.be.undefined;

  eventsLib = await new Events__factory(deployer).deploy();
});
