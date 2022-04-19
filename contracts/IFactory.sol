// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
interface IFactory {
    function getExchange(address _tokenAddress) external view returns (address);
}