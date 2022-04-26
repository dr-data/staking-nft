// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IToken.sol";

contract Minter is Ownable {
    IToken public token;

    mapping(address => bool) private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender) == true, "PinkMinterV1: caller is not the minter");
        _;
    }

    receive() external payable {}

    function setToken(address _token) external onlyOwner {
        token = IToken(_token);
    }

    function tokenToMint() public view returns (address) {
        return address(token);
    }

    function transferTokenOwner(address _owner) external onlyOwner {
        Ownable(address(token)).transferOwnership(_owner);
    }

    function setMinter(address minter, bool canMint) external onlyOwner {
        if (canMint) {
            _minters[minter] = canMint;
        } else {
            delete _minters[minter];
        }
    }

    function isMinter(address _minter) public view returns (bool) {
        if (Ownable(address(token)).owner() != address(this)) {
            return false;
        }
        return _minters[_minter];
    }

    function mintFor(address to, uint256 amount) external onlyMinter {
        if (amount == 0) return;
        _mint(to, amount);
    }

    function _mint(address _to, uint256 _amount) internal {
        token.mint(_to, _amount);
        // commission for devTeam
        uint256 forDev = (_amount * 15) / 100;
        token.mint(owner(), forDev);
    }

    function rescueFunds(address _token) external onlyOwner {
        require(_token != address(token), "wut?");

        if (_token == address(0)) {
            (bool suc, ) = msg.sender.call{value: address(this).balance}("");
            require(suc);
        } else {
            require(IToken(_token).transfer(msg.sender, IToken(_token).balanceOf(address(this))));
        }
    }
}
