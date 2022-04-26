// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IMinter.sol";

contract NFTStaking is Ownable, IERC721Receiver {
    uint256 public totalStaked;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        uint256 lastHarvest;
        address owner;
    }

    // reference to the Block NFT contract
    IERC20 token;
    IMinter minter;

    // maps erc721 contract, tokenId to stake
    mapping(address => mapping(uint256 => Stake)) public vault;
    //
    mapping(address => uint256) public rewardPerSecond;
    mapping(address => bool) public poolExists;
    //
    uint256 public startTime;

    event NFTStaked(address owner, address collection, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    function addCollection(address _collection, uint256 _rewardPerSecond) external onlyOwner {
        require(_collection != address(0));
        require(poolExists[_collection] == false, "Pool already exists");

        poolExists[_collection] = true;
        rewardPerSecond[_collection] = _rewardPerSecond;
    }

    function setCollection(address _collection, uint256 _rewardPerSecond) external onlyOwner {
        require(_collection != address(0));
        require(poolExists[_collection] == true, "Pool does not exist");

        rewardPerSecond[_collection] = _rewardPerSecond;
    }

    function stake(address _collection, uint256[] calldata tokenIds) external {
        require(poolExists[_collection] == true, "Pool does not exist");
        require(tokenIds.length > 0, "No tokenIds provided");

        uint256 tokenId;
        // totalStaked += tokenIds.length;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(IERC721(_collection).ownerOf(tokenId) == msg.sender, "not your token");
            require(vault[_collection][tokenId].tokenId == 0, "already staked");

            IERC721(_collection).safeTransferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, _collection, tokenId, block.timestamp);

            vault[_collection][tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp),
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

    function _claim(address _collection, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        uint256 total = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake storage staked = vault[_collection][tokenId];
            require(staked.owner == msg.sender, "not an owner");

            // start
            uint256 timeElasped;
            if (staked.lastHarvest > startTime) {
                timeElasped = block.timestamp - staked.lastHarvest;
            } else {
                timeElasped = block.timestamp > startTime ? block.timestamp - startTime : 0;
            }

            staked.lastHarvest = block.timestamp;

            total += timeElasped;
        }

        require(total > 0, "no time has passed");

        uint256 amount = total * rewardPerSecond[_collection];
        require(amount > 0, "no reward");

        minter.mintFor(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }

    function earned(address _collection, uint256[] calldata tokenIds) external view returns (uint256 amount) {
        uint256 tokenId;
        uint256 total = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[_collection][tokenId];
            require(staked.owner == msg.sender, "not an owner");

            // start
            uint256 timeElasped;
            if (staked.lastHarvest > startTime) {
                timeElasped = block.timestamp - staked.lastHarvest;
            } else {
                timeElasped = block.timestamp > startTime ? block.timestamp - startTime : 0;
            }

            total += timeElasped;
        }

        if (total > 0) {
            amount = total * rewardPerSecond[_collection];
        } else {
            amount = 0;
        }
    }

    // should never be used inside of transaction because of gas fee
    // function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

    //   uint256 supply = nft.totalSupply();
    //   uint256[] memory tmp = new uint256[](supply);

    //   uint256 index = 0;
    //   for(uint tokenId = 1; tokenId <= supply; tokenId++) {
    //     if (vault[tokenId].owner == account) {
    //       tmp[index] = vault[tokenId].tokenId;
    //       index +=1;
    //     }
    //   }

    //   uint256[] memory tokens = new uint256[](index);
    //   for(uint i = 0; i < index; i++) {
    //     tokens[i] = tmp[i];
    //   }

    //   return tokens;
    // }

    function _unstakeMany(
        address account,
        address _collection,
        uint256[] calldata tokenIds
    ) internal {
        uint256 tokenId;
        // totalStaked -= tokenIds.length;
        _claim(_collection, tokenIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[_collection][tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[_collection][tokenId];
            emit NFTUnstaked(account, tokenId, block.timestamp);
            IERC721(_collection).safeTransferFrom(address(this), account, tokenId);
        }
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}
