
import {
    makeSuiteCleanRoom,deployer, x404Hub, owner, deployerAddress
} from '../__setup.spec';
import { expect } from 'chai';
import { ERRORS } from '../helpers/errors';
import { findEvent, waitForTx } from '../helpers/utils';

import {
    BlueChipNFT__factory
} from '../../typechain-types';
import { ZERO_ADDRESS } from '../helpers/constants';

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
                await expect(x404Hub.connect(deployer).SetBlueChipNftContract([blueChipAddr], true)).to.be.not.reverted
                await expect(x404Hub.connect(deployer).setNewRedeemDeadline(0)).to.be.revertedWithCustomError(x404Hub, ERRORS.InvaildRedeemMaxDeadline)
            });
            it('User should fail to create if emergce closed.',   async function () {
                await expect(x404Hub.connect(deployer).emergencyClose(true)).to.be.not.reverted
                await expect(x404Hub.connect(deployer).createX404(blueChipAddr)).to.be.revertedWithCustomError(x404Hub, ERRORS.EmergencyClose)
            });
            it('User should fail to create if created twice.',   async function () {
                await expect(x404Hub.connect(deployer).SetBlueChipNftContract([blueChipAddr], true)).to.be.not.reverted
                await expect(x404Hub.connect(deployer).createX404(blueChipAddr)).to.be.not.reverted
                await expect(x404Hub.connect(deployer).createX404(blueChipAddr)).to.be.reverted
            });
        })

        context('Scenarios', function () {
            it('User should correct varliable if created success.',   async function () {
                await expect(x404Hub.connect(deployer).SetBlueChipNftContract([blueChipAddr], true)).to.be.not.reverted
                expect(await x404Hub.connect(deployer)._blueChipNftContract(blueChipAddr)).to.equal(true)

                const receipt = await waitForTx(x404Hub.connect(deployer).createX404(blueChipAddr))
                const event = findEvent(receipt, 'X404Created');
                const x404Address = event!.args[0];
                expect(await x404Hub.connect(deployer)._x404Contract(blueChipAddr)).to.equal(x404Address)
            });
        })
    })
})