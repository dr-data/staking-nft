// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BatchTransfer {
    address operator;

    constructor() {
        operator = msg.sender;
    }

    function batchTransfer(
        IERC20 _token,
        address[] memory _to,
        uint256[] memory _value
    ) external {
        for (uint256 i = 0; i < _to.length; i++) {
            _token.transfer(_to[i], _value[i]);
        }
    }

    function setOperator(address _operator) external {
        require(_operator != address(0));
        require(msg.sender == operator);
        operator = _operator;
    }

    function rescueFund(IERC20 _token) public {
        require(msg.sender == operator);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
}
