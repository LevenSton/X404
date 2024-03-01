// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Events {
    event SendTomojiToken(
        address indexed sponsor,
        string name,
        uint256 emojiClaimId,
        uint256 emojiTokenAmount
    );

    event X404Created(
        address indexed addr,
        address indexed blueChipNftAddr,
        address indexed creator
    );

    event X404ReceiptNFT(
        address indexed caller,
        address indexed from,
        uint256 indexed tokenId,
        uint256 redeemDeadline
    );
}
