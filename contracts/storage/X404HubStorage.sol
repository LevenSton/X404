// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {DataTypes} from "../lib/DataTypes.sol";

abstract contract X404HubStorage {
    DataTypes.CreateX404Parameters public _parameters;
    bool public _bNoPermission;
    bool public _emergencyClose;
    uint256 public redeemMaxDeadline;
    DataTypes.SwapRouter[] public _swapRouterAddr;
    mapping(address => bool) public _blueChipNftContract;
    mapping(address => address) public _x404Contract;
}
