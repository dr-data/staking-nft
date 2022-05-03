// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721mock is ERC721 {
    constructor() ERC721("mockName", "mockSymbol") {
        for (uint256 i = 1; i < 11; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function mintTo(address _to, uint256 _tokenId) external {
        _mint(_to, _tokenId);
    }
}
