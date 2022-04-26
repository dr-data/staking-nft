// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IMinter {
    function mintFor(address _to, uint256 _amount) external;
}
