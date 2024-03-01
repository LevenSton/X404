// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Errors {
    error InvaildLength();
    error InvaildParam();
    error OnlyCallByFactory();
    error NotFound();
    error NoPermission();
    error NotBlueChipNFT(address nftContractAddr);
    error X404NotCreate();
    error CantBeZeroAddress();
    error X404SwapV3FactoryMismatch();
    error ErrorNFTAddress();
    error DeadLineInvaild();
    error InvalidTokenId();
    error NotNFTOriginOwner();
    error RemoveFailed();
    error NotEnoughValiedSubjectMatterToSend();
}
