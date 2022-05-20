// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface INftLocker {
    struct NftLockList {
        uint24 tokenId;
        uint256 releaseTime;
        bool released;
    }
    struct Lockup {
        NftLockList[] lockedList;
        uint256 unlockable;
    }

    function lockup(address _collection, address _usr) external view returns (Lockup memory);

    function lock(
        address _usr,
        address _collection,
        uint24 _tokenId
    ) external;

    function unlock(address _collection) external;

    function unlockableNft(address _usr, address _collection) external view returns (NftLockList[] memory nfts);
}
