// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KlayLionsCoin is ERC20Pausable, Ownable {
    uint256 public constant MAX_SUPPLY = 229156125e17;

    constructor() ERC20("t", "tt") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
