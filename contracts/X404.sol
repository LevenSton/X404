// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC404} from "./ERC404.sol";
import {IX404Hub} from "./interfaces/IX404Hub.sol";
import {IPeripheryImmutableState} from "./interfaces/IPeripheryImmutableState.sol";
import {IUniswapV2Router} from "./interfaces/IUniswapV2Router.sol";
import {DataTypes} from "./lib/DataTypes.sol";
import {Errors} from "./lib/Errors.sol";
import {Events} from "./lib/Events.sol";
import {LibCaculatePair} from "./lib/LibCaculatePair.sol";
import {X404Storage} from "./storage/X404Storage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract X404 is IERC721Receiver, ERC404, Ownable, X404Storage {
    using EnumerableSet for EnumerableSet.UintSet;

    address public immutable creator;
    address public immutable blueChipNftAddr;
    address public immutable factory;

    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert Errors.OnlyCallByFactory();
        }
        _;
    }

    constructor() Ownable(msg.sender) {
        decimals = 18;
        uint256 nftUints;
        (blueChipNftAddr, creator, maxRedeemDeadline, nftUints) = IX404Hub(
            msg.sender
        )._parameters();

        units = nftUints * 10 ** 18;
        address newOwner = IX404Hub(msg.sender).owner();
        string memory oriName = IERC721Metadata(blueChipNftAddr).name();
        string memory oriSymbol = IERC721Metadata(blueChipNftAddr).symbol();
        name = string.concat("X404-", oriName);
        symbol = string.concat("X404-", oriSymbol);
        DataTypes.SwapRouter[] memory swapRouterStruct = IX404Hub(msg.sender)
            .getSwapRouter();
        _setRouterTransferExempt(swapRouterStruct);
        _setERC721TransferExempt(address(this), true);
        factory = msg.sender;
        _transferOwnership(newOwner);
    }

    function depositSubjectMatter(
        uint256[] calldata tokenIds,
        uint256 redeemDeadline
    ) external {
        if (
            redeemDeadline < block.timestamp ||
            redeemDeadline > block.timestamp + maxRedeemDeadline
        ) {
            revert Errors.DeadLineInvaild();
        }
        uint256 len = tokenIds.length;
        if (len == 0) {
            revert Errors.InvaildLength();
        }
        for (uint256 i = 0; i < len; ) {
            IERC721Metadata(blueChipNftAddr).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
            if (tokenIdSet.add(tokenIds[i])) {
                SubjectMatterInfo storage subInfo = subjectInfo[tokenIds[i]];
                subInfo.caller = msg.sender;
                subInfo.oriOwner = msg.sender;
                subInfo.redeemDeadline = redeemDeadline;
            } else {
                revert Errors.InvalidTokenId();
            }
            emit Events.X404ReceiptNFT(
                msg.sender,
                msg.sender,
                tokenIds[i],
                redeemDeadline
            );
            unchecked {
                i++;
            }
        }
        _transferERC20WithERC721(address(0), msg.sender, len * units);
    }

    function redeemSubjectMatter(uint256[] calldata tokenIds) external {
        uint256 len = tokenIds.length;
        if (len == 0) {
            revert Errors.InvaildLength();
        }

        _transferERC20WithERC721(msg.sender, address(0), units * len);

        for (uint256 i = 0; i < tokenIds.length; ) {
            if (
                subjectInfo[tokenIds[i]].oriOwner != msg.sender &&
                subjectInfo[tokenIds[i]].redeemDeadline > block.timestamp
            ) {
                revert Errors.NFTCannotRedeem();
            }
            IERC721Metadata(blueChipNftAddr).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
            delete subjectInfo[tokenIds[i]];
            if (!tokenIdSet.remove(tokenIds[i])) {
                revert Errors.RemoveFailed();
            }
            unchecked {
                i++;
            }
        }
    }

    function onERC721Received(
        address caller,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        if (msg.sender != blueChipNftAddr) {
            revert Errors.ErrorNFTAddress();
        }
        uint256 redeemDeadline = abi.decode(data, (uint256));
        if (
            redeemDeadline < block.timestamp ||
            redeemDeadline > block.timestamp + maxRedeemDeadline
        ) {
            revert Errors.DeadLineInvaild();
        }
        _transferERC20WithERC721(address(0), from, units);
        if (tokenIdSet.add(tokenId)) {
            SubjectMatterInfo storage subInfo = subjectInfo[tokenId];
            subInfo.caller = caller;
            subInfo.oriOwner = from;
            subInfo.redeemDeadline = redeemDeadline;
        } else {
            revert Errors.InvalidTokenId();
        }
        emit Events.X404ReceiptNFT(caller, from, tokenId, redeemDeadline);

        return IERC721Receiver.onERC721Received.selector;
    }

    function getTokenIdSet() external view returns (uint256[] memory) {
        return tokenIdSet.values();
    }

    function checkTokenIdExsit(uint256 tokenId) external view returns (bool) {
        return tokenIdSet.contains(tokenId);
    }

    function getTokenIdByIndex(uint256 index) external view returns (uint256) {
        return tokenIdSet.at(index);
    }

    /**************Only Call By Factory Function **********/

    function setContractURI(
        string calldata newContractUri
    ) public onlyFactory returns (bool) {
        contractURI = newContractUri;
        return true;
    }

    function setTokenURI(string calldata _tokenURI) public onlyFactory {
        baseTokenURI = _tokenURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseTokenURI, Strings.toString(id));
    }

    /**************Internal Function **********/
    function _setRouterTransferExempt(
        DataTypes.SwapRouter[] memory swapRouterStruct
    ) internal {
        address thisAddress = address(this);
        for (uint i = 0; i < swapRouterStruct.length; ) {
            address routerAddr = swapRouterStruct[i].routerAddr;
            if (routerAddr == address(0)) {
                revert Errors.CantBeZeroAddress();
            }
            _setERC721TransferExempt(routerAddr, true);

            if (swapRouterStruct[i].bV2orV3) {
                address weth_ = IUniswapV2Router(routerAddr).WETH();
                address swapFactory = IUniswapV2Router(routerAddr).factory();
                address pair = LibCaculatePair._getUniswapV2Pair(
                    swapFactory,
                    thisAddress,
                    weth_
                );
                _setERC721TransferExempt(pair, true);
            } else {
                address weth_ = IPeripheryImmutableState(routerAddr).WETH9();
                address swapFactory = IPeripheryImmutableState(routerAddr)
                    .factory();
                address v3NonfungiblePositionManager = swapRouterStruct[i]
                    .uniswapV3NonfungiblePositionManager;
                if (v3NonfungiblePositionManager == address(0)) {
                    revert Errors.CantBeZeroAddress();
                }
                if (
                    IPeripheryImmutableState(v3NonfungiblePositionManager)
                        .factory() !=
                    swapFactory ||
                    IPeripheryImmutableState(v3NonfungiblePositionManager)
                        .WETH9() !=
                    weth_
                ) {
                    revert Errors.X404SwapV3FactoryMismatch();
                }
                _setERC721TransferExempt(v3NonfungiblePositionManager, true);
                _setV3SwapTransferExempt(swapFactory, thisAddress, weth_);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _setV3SwapTransferExempt(
        address swapFactory,
        address tokenA,
        address tokenB
    ) internal {
        uint24[4] memory feeTiers = [
            uint24(100),
            uint24(500),
            uint24(3_000),
            uint24(10_000)
        ];

        for (uint256 i = 0; i < feeTiers.length; ) {
            address v3PairAddr = LibCaculatePair._getUniswapV3Pair(
                swapFactory,
                tokenA,
                tokenB,
                feeTiers[i]
            );
            // Set the v3 pair as exempt.
            _setERC721TransferExempt(v3PairAddr, true);
            unchecked {
                ++i;
            }
        }
    }
}
