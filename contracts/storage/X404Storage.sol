// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract X404Storage {
    string public baseTokenURI;
    string public contractURI;

    //if not redeem your nft before deadline, others who hold units token maybe can get your nft, if no one get, you also can get your origin nft.
    uint256 public maxRedeemDeadline;

    struct SubjectMatterInfo {
        address caller;
        address oriOwner;
        uint256 redeemDeadline;
    }

    EnumerableSet.UintSet internal tokenIdSet;
    mapping(uint256 => SubjectMatterInfo) public subjectInfo;
}
