// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KlayLionsCoin is ERC20Pausable, Ownable {
    uint256 public constant INITIAL_MINT_AMOUNT = 1000000000000000000;

    constructor() ERC20("KlayLionsCoin", "KLC") {
        _mint(msg.sender, INITIAL_MINT_AMOUNT);
    }

    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
