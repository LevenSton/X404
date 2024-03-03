
import {
    makeSuiteCleanRoom,deployer, x404Hub, owner, deployerAddress, user, yestoday, tomorrow, tomorrow2
} from '../__setup.spec';
import { expect } from 'chai';
import { ERRORS } from '../helpers/errors';
import { findEvent, waitForTx } from '../helpers/utils';

import {
    BlueChipNFT,
    BlueChipNFT__factory, X404, X404__factory
} from '../../typechain-types';

makeSuiteCleanRoom('depositSubjectMatter', function () {
    const ContractURI = "https://xrgb.xyz/contract"
    const TokenURI = "https://xrgb.xyz/metadata/"

    context('Generic', function () {
        let nft0Addr: string;
        let blueChipAddr: string;
        let x404: X404;
        let blueChipNft: BlueChipNFT;
        beforeEach(async function () {
            const nft0 = await new BlueChipNFT__factory(deployer).deploy();
            nft0Addr = await nft0.getAddress();
            const nft1 = await new BlueChipNFT__factory(deployer).deploy();
            blueChipAddr = await nft1.getAddress();

            await expect(x404Hub.connect(owner).SetBlueChipNftContract([blueChipAddr], true)).to.be.not.reverted
            expect(await x404Hub.connect(owner)._blueChipNftContract(blueChipAddr)).to.equal(true)

            const receipt = await waitForTx(x404Hub.connect(deployer).createX404(blueChipAddr))
            const event = findEvent(receipt, 'X404Created');
            const x404Addr = event!.args[0];
            expect(await x404Hub.connect(deployer)._x404Contract(blueChipAddr)).to.equal(x404Addr)
            expect(await x404Hub.connect(owner).setContractURI(blueChipAddr, ContractURI)).to.be.not.reverted

            x404 = X404__factory.connect(x404Addr)
            expect(await x404.connect(owner).contractURI()).to.equal(ContractURI)
            expect(await x404Hub.connect(owner).setTokenURI(blueChipAddr, TokenURI)).to.be.not.reverted

            blueChipNft = BlueChipNFT__factory.connect(blueChipAddr)
            expect(await blueChipNft.connect(user).mint()).to.be.not.reverted
        });
        
        context('Negatives', function () {
            it('User should fail to deposit if deadline less than now.',   async function () {
                await expect(x404.connect(user).depositSubjectMatter([0], yestoday)).to.be.revertedWithCustomError(x404, ERRORS.DeadLineInvaild)
            });
            it('User should fail to deposit if deadline large than max deadlin.',   async function () {
                await expect(x404.connect(user).depositSubjectMatter([0], tomorrow2)).to.be.revertedWithCustomError(x404, ERRORS.DeadLineInvaild)
            });
            it('User should fail to deposit if not approve nft to contract.',   async function () {
                await expect(x404.connect(user).depositSubjectMatter([0], tomorrow)).to.be.reverted
            });
        })

        context('Scenarios', function () {
        })
    })
})