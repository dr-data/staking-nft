// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMinter.sol";

import "hardhat/console.sol";

contract NftChef is Ownable, IERC721Receiver {
    /* ========== STATE VARIABLES ========== */

    // NFT 스테이킹 구조체
    struct Stake {
        uint24 tokenId;
        uint256 timestamp; // 흠.. 락업,,
        uint256 lastHarvest;
        address owner;
    }

    // 민팅 권한을 가진  컨트랙트
    IMinter public minter;

    // [NFT][ID] => Stake
    mapping(address => mapping(uint256 => Stake)) public vault;

    // 분배 비율 변경 전 리워드 분배 비율 저장
    mapping(address => uint256) public rewardPerSecondStored;

    // 분배 비율 변경 시점
    mapping(address => uint256) public lastUpdate;

    // 현 리워드 분배 비율
    mapping(address => uint256) public rewardPerSecond;

    // 해당 NFT 컬렉션이 리워드 풀로 존재하는 지 확인
    mapping(address => bool) public poolExists;

    // 스테이킹 된 NFT 수량
    mapping(address => uint256) public totalStaked;

    // 리워드 시작 시점
    uint256 public startTime;

    /* ========== EVENTS ========== */

    event NFTStaked(address owner, address collection, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, address collection, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    /* ========== INITIALIZER ========== */

    constructor(address _minter, uint256 _startTime) {
        minter = IMinter(_minter);
        // startTime = _startTime;
        startTime = block.timestamp;
    }

    /* ========== VIEWS ========== */

    function isPoolExists(address _collection) public view returns (bool) {
        return poolExists[_collection];
    }

    function rewardToken() public view returns (address) {
        return minter.tokenToMint();
    }

    function earned(address _collection, uint256[] calldata tokenIds) external view returns (uint256 amount) {
        uint256 tokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[_collection][tokenId];

            uint256 reward;
            uint256 startTimeStamp = startTime < staked.lastHarvest ? staked.lastHarvest : startTime;

            if (startTimeStamp < lastUpdate[_collection] && lastUpdate[_collection] < block.timestamp) {
                reward =
                    rewardPerSecondStored[_collection] *
                    (lastUpdate[_collection] - startTimeStamp) +
                    rewardPerSecond[_collection] *
                    (block.timestamp - lastUpdate[_collection]);
            } else {
                if (block.timestamp < startTimeStamp) {
                    reward = 0;
                } else {
                    reward = rewardPerSecond[_collection] * (block.timestamp - startTimeStamp);
                }
            }
            amount += reward;
        }
    }

    // 가스비 많이 드니까 컨트랙트에서 부르지 않기
    function tokensOfOwner(address account, address _collection) public view returns (uint256[] memory ownerTokens) {
        uint256 supply = totalStaked[_collection];
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (vault[_collection][tokenId].owner == account) {
                tmp[index] = vault[_collection][tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(address _collection, uint256[] calldata tokenIds) external {
        require(poolExists[_collection] == true, "Pool does not exist");
        require(tokenIds.length > 0, "No tokenIds provided");

        uint256 tokenId;
        totalStaked[_collection] += tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(IERC721(_collection).ownerOf(tokenId) == msg.sender, "not your token");
            require(vault[_collection][tokenId].tokenId == 0, "already staked");

            IERC721(_collection).safeTransferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, _collection, tokenId, block.timestamp);

            vault[_collection][tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint256(block.timestamp),
                lastHarvest: block.timestamp
            });
        }
    }

    function unstake(
        address account,
        address _collection,
        uint256[] calldata tokenIds
    ) external {
        require(poolExists[_collection] == true, "Pool does not exist");
        _unstakeMany(account, _collection, tokenIds);
    }

    function claim(address _collection, uint256[] calldata tokenIds) external {
        require(poolExists[_collection] == true, "Pool does not exist");
        _claim(_collection, tokenIds);
    }

    /* ========== ADMIN FUNCITONS ======== */

    function addCollection(address _collection, uint256 _rewardPerSecond) external onlyOwner {
        require(_collection != address(0));
        require(poolExists[_collection] == false, "Pool already exists");

        poolExists[_collection] = true;
        rewardPerSecond[_collection] = _rewardPerSecond;
    }

    function setCollection(address _collection, uint256 _rewardPerSecond) external onlyOwner {
        require(_collection != address(0));
        require(poolExists[_collection] == true, "Pool does not exist");

        rewardPerSecondStored[_collection] = rewardPerSecond[_collection];
        lastUpdate[_collection] = block.timestamp;

        rewardPerSecond[_collection] = _rewardPerSecond;
    }

    function setMinter(address _minter) external onlyOwner {
        console.log("set minter", address(minter), "to", _minter);
        minter = IMinter(_minter);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _claim(address _collection, uint256[] calldata tokenIds) internal {
        require(startTime < block.timestamp, "Claim has not started");
        uint256 tokenId;
        uint256 amount;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake storage staked = vault[_collection][tokenId];
            require(staked.owner == msg.sender, "not an owner");

            // start
            uint256 reward;
            uint256 startTimeStamp = startTime < staked.lastHarvest ? staked.lastHarvest : startTime;

            if (startTimeStamp < lastUpdate[_collection] && lastUpdate[_collection] < block.timestamp) {
                reward =
                    rewardPerSecondStored[_collection] *
                    (lastUpdate[_collection] - startTimeStamp) +
                    rewardPerSecond[_collection] *
                    (block.timestamp - lastUpdate[_collection]);
            } else {
                reward = rewardPerSecond[_collection] * (block.timestamp - startTimeStamp);
            }

            staked.lastHarvest = block.timestamp;
            amount += reward;
        }

        if (amount > 0) {
            minter.mintFor(msg.sender, amount);
        }

        emit Claimed(msg.sender, amount);
    }

    function _unstakeMany(
        address account,
        address _collection,
        uint256[] calldata tokenIds
    ) internal {
        uint256 tokenId;
        totalStaked[_collection] -= tokenIds.length;
        _claim(_collection, tokenIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[_collection][tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[_collection][tokenId];
            emit NFTUnstaked(account, _collection, tokenId, block.timestamp);
            IERC721(_collection).safeTransferFrom(address(this), account, tokenId);
        }
    }

    function emergencyWithdraw(
        address account,
        address _collection,
        uint256[] calldata tokenIds
    ) public {
        uint256 tokenId;
        totalStaked[_collection] -= tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[_collection][tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[_collection][tokenId];
            emit NFTUnstaked(account, _collection, tokenId, block.timestamp);
            IERC721(_collection).safeTransferFrom(address(this), account, tokenId);
        }
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
