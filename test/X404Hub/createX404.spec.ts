
import {
    makeSuiteCleanRoom,deployer, x404Hub, owner, deployerAddress
} from '../__setup.spec';
import { expect } from 'chai';
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';
import { waitForTx } from '../helpers/utils';

import {
    BlueChipNFT__factory
} from '../../typechain-types';

makeSuiteCleanRoom('create X404', function () {
    context('Generic', function () {
        let nft0Addr: string;
        let blueChipAddr: string;
        beforeEach(async function () {
            const nft0 = await new BlueChipNFT__factory(deployer).deploy();
            nft0Addr = await nft0.getAddress();
            const nft1 = await new BlueChipNFT__factory(deployer).deploy();
            blueChipAddr = await nft1.getAddress();
        });
        
        context('Negatives', function () {
            it('User should fail to create if nft is not blurchip.',   async function () {
                await expect(x404Hub.connect(owner).createX404(nft0Addr)).to.be.revertedWithCustomError(x404Hub, ERRORS.NotBlueChipNFT)
            });
            it('User should fail to create if redeemMaxDeadline not initialized.',   async function () {
                await expect(x404Hub.connect(deployer).SetBlueChipNftContract([nft0Addr], true)).to.be.not.reverted
                //await x404Hub.connect(deployer).SetBlueChipNftContract([nft0Addr], true)
                //await expect(x404Hub.connect(owner).createX404(nft0Addr)).to.be.revertedWithCustomError(x404Hub, ERRORS.NotBlueChipNFT)
            });
        })

        context('Scenarios', function () {
            
        })
    })
})