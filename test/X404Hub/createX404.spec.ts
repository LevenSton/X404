
import {
    makeSuiteCleanRoom,deployer
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
        let nft0Addr;
        let blueChipAddr;
        beforeEach(async function () {
            const nft0 = await new BlueChipNFT__factory(deployer).deploy();
            nft0Addr = nft0.getAddress()
            const nft1 = await new BlueChipNFT__factory(deployer).deploy();
            blueChipAddr = nft1.getAddress()
        });
        
        context('Negatives', function () {
            
        })

        context('Scenarios', function () {
            
        })
    })
})