// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftLocker is Ownable, IERC721Receiver {
    struct NftLockList {
        uint24 tokenId;
        uint256 releaseTime;
        bool released;
    }
    struct Lockup {
        NftLockList[] lockedList;
        uint256 unlockable;
    }

    mapping(address => mapping(address => Lockup)) public lockup;

    uint256 public lockupDuration = 1200;

    address public nftPool;

    constructor(address _nftPool) {
        nftPool = _nftPool;
    }

    modifier onlyNftPool() {
        require(msg.sender == nftPool);
        _;
    }

    function lock(
        address account,
        address _collection,
        uint24 tokenId
    ) public onlyNftPool {
        _lock(account, _collection, tokenId);
    }

    function _lock(
        address account,
        address _collection,
        uint24 tokenId
    ) internal {
        IERC721(_collection).safeTransferFrom(nftPool, address(this), tokenId);

        Lockup storage userLock = lockup[_collection][account];

        userLock.lockedList.push(NftLockList({tokenId: tokenId, releaseTime: block.timestamp + lockupDuration, released: false}));
    }

    function unlock(address _collection) external {
        Lockup storage userLock = lockup[_collection][msg.sender];

        for (uint256 i = 0; i < userLock.lockedList.length; i++) {
            if (userLock.lockedList[i].released == false) {
                if (block.timestamp > userLock.lockedList[i].releaseTime) {
                    IERC721(_collection).safeTransferFrom(address(this), msg.sender, userLock.lockedList[i].tokenId);
                    userLock.lockedList[i].released = true;
                }
            }
        }
    }

    function unlockableNft(address account, address _collection) public view returns (NftLockList[] memory nfts) {
        uint256 totalUnlockable;

        Lockup memory userLock = lockup[_collection][account];

        for (uint256 i = 0; i < userLock.lockedList.length; i++) {
            if (!userLock.lockedList[i].released) {
                totalUnlockable += 1;
            }
        }

        nfts = new NftLockList[](totalUnlockable);

        uint256 index = 0;
        for (uint256 i = 0; i < userLock.lockedList.length; i++) {
            if (!userLock.lockedList[i].released) {
                nfts[index] = userLock.lockedList[i];
                index += 1;
            }
        }
    }

    function setNftPool(address _nftPool) public onlyOwner {
        nftPool = _nftPool;
    }

    function resetUser(address _collection, address _usr) external onlyOwner {
        Lockup storage userLock = lockup[_collection][_usr];
        for (uint256 i = 0; i < userLock.lockedList.length; i++) {
            if (userLock.lockedList[i].released == false) {
                IERC721(_collection).safeTransferFrom(address(this), _usr, userLock.lockedList[i].tokenId);
                userLock.lockedList[i].released = true;
            }
        }
    }

    function rescueNft(address _collection, uint256 _tokenId) public onlyOwner {
        IERC721(_collection).safeTransferFrom(address(this), owner(), _tokenId);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
