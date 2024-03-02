
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

  expect(x404Hub).to.not.be.undefined;

  eventsLib = await new Events__factory(deployer).deploy();
});
