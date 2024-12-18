// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {X404HubStorage} from "./storage/X404HubStorage.sol";
import {DataTypes} from "./lib/DataTypes.sol";
import {Errors} from "./lib/Errors.sol";
import {Events} from "./lib/Events.sol";
import {X404} from "./X404.sol";

contract X404Hub is OwnableUpgradeable, X404HubStorage {
    modifier checkPermission(address nftContractAddress) {
        if (_emergencyClose) {
            revert Errors.EmergencyClose();
        }
        if (!_bNoPermission) {
            if (!_blueChipNftContract[nftContractAddress]) {
                revert Errors.NotBlueChipNFT();
            }
        }
        if (redeemMaxDeadline == 0) {
            revert Errors.InvaildRedeemMaxDeadline();
        }
        _;
    }

    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(
        address owner,
        uint256 maxRedeemDeadline,
        DataTypes.SwapRouter[] calldata swapRouterAddr
    ) public initializer {
        __Ownable_init(owner);
        if (maxRedeemDeadline == 0) {
            revert Errors.InvaildRedeemMaxDeadline();
        }
        for (uint256 i = 0; i < swapRouterAddr.length; i++) {
            _swapRouterAddr.push(swapRouterAddr[i]);
        }
        redeemMaxDeadline = maxRedeemDeadline;
    }

    function createX404(
        address nftContractAddress,
        uint256 nftUnits
    ) external checkPermission(nftContractAddress) returns (address x404) {
        _parameters = DataTypes.CreateX404Parameters({
            nftContractAddr: nftContractAddress,
            creator: msg.sender,
            redeemMaxDeadline: redeemMaxDeadline,
            nftUnits: nftUnits
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
        X404(_x404Contract[nftContract]).setTokenURI(newTokenURI);
    }

    function setNewRedeemDeadline(uint256 newDeadline) public onlyOwner {
        if (newDeadline == 0) {
            revert Errors.InvaildRedeemMaxDeadline();
        }
        redeemMaxDeadline = newDeadline;
    }

    function setSwapRouter(
        DataTypes.SwapRouter[] memory swapRouterAddr
    ) public onlyOwner {
        delete _swapRouterAddr;
        for (uint256 i = 0; i < swapRouterAddr.length; ) {
            _swapRouterAddr.push(swapRouterAddr[i]);
            unchecked {
                i++;
            }
        }
    }

    function emergencyClose(bool bClose) public onlyOwner {
        _emergencyClose = bClose;
    }

    function SetBlueChipNftContract(
        address[] memory contractAddrs,
        bool state
    ) public onlyOwner {
        for (uint256 i = 0; i < contractAddrs.length; ) {
            if (contractAddrs[i] == address(0x0)) {
                revert Errors.CantBeZeroAddress();
            }
            _blueChipNftContract[contractAddrs[i]] = state;
            unchecked {
                i++;
            }
        }
    }

    function getSwapRouter()
        public
        view
        returns (DataTypes.SwapRouter[] memory)
    {
        return _swapRouterAddr;
    }
}
