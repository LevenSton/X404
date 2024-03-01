// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {X404HubStorage} from "./storage/X404HubStorage.sol";
import {DataTypes} from "./lib/DataTypes.sol";
import {Errors} from "./lib/Errors.sol";
import {Events} from "./lib/Events.sol";
import {X404} from "./X404.sol";

contract X404Hub is Initializable, OwnableUpgradeable, X404HubStorage {
    modifier checkPermission() {
        if (!_bNoPermission) {
            if (msg.sender != owner()) {
                revert Errors.NoPermission();
            }
        }
        _;
    }

    function initialize(
        address owner,
        uint256 maxRedeemDeadline,
        DataTypes.SwapRouter[] memory swapRouterAddr
    ) public initializer {
        __Ownable_init(owner);
        for (uint256 i = 0; i < swapRouterAddr.length; i++) {
            _swapRouterAddr.push(swapRouterAddr[i]);
        }
        redeemMaxDeadline = maxRedeemDeadline;
    }

    function createX404(
        address nftContractAddress
    ) external checkPermission returns (address x404) {
        if (!_blueChipNftContract[nftContractAddress]) {
            revert Errors.NotBlueChipNFT(nftContractAddress);
        }
        _parameters = DataTypes.CreateX404Parameters({
            nftContractAddr: nftContractAddress,
            creator: msg.sender,
            redeemMaxDeadline: redeemMaxDeadline
        });
        x404 = address(
            new X404{salt: keccak256(abi.encode(nftContractAddress))}()
        );
        _x404Contract[nftContractAddress] = x404;
        delete _parameters;
        emit Events.X404Created(x404, nftContractAddress, msg.sender);
    }

    function setContractURI(
        address nftContract,
        string calldata newContractUri
    ) public onlyOwner {
        if (_x404Contract[nftContract] == address(0)) {
            revert Errors.X404NotCreate();
        }
        X404(_x404Contract[nftContract]).setContractURI(newContractUri);
    }

    function setTokenURI(
        address nftContract,
        string calldata newTokenURI
    ) public onlyOwner {
        if (_x404Contract[nftContract] == address(0)) {
            revert Errors.X404NotCreate();
        }
        X404(_x404Contract[nftContract]).setContractURI(newTokenURI);
    }

    function setNewRedeemDeadline(uint256 newDeadline) public onlyOwner {
        redeemMaxDeadline = newDeadline;
    }

    // function setSwapRouter(
    //     DataTypes.SwapRouter[] memory swapRouterAddr
    // ) public onlyOwner {
    //     _swapRouterAddr = swapRouterAddr;
    // }

    function getSwapRouter()
        public
        view
        returns (DataTypes.SwapRouter[] memory)
    {
        return _swapRouterAddr;
    }
}
