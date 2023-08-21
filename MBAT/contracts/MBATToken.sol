// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Staking.sol";
import "./Marketplace.sol";
import "./BiometricVerifier.sol";
import "./SocialNetworkIdentification.sol";
import "./UserProfile.sol"; // Importing the UserProfile contract
import "./UserIdentity.sol"; // Importing the UserIdentity contract

contract MBATToken {
    string public constant name = "MobileBioAuth Token";
    string public constant symbol = "MBAT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    bool public paused; // To pause token transfers in case of emergencies

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Identity Mapping
    mapping(address => bytes32) private encryptedDocuments; // Encrypted documents or document hashes
    mapping(address => bool) private authorizedEntities; // Authorized entities to access specific identification data

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Paused(bool status);

    Staking private _stakingContract;
    Marketplace private _marketplaceContract;
    BiometricVerifier private _biometricVerifier; 
    SocialNetworkIdentification private _socialNetworkIdentification;
    UserIdentity private _userIdentity; // Adding UserIdentity contract

    struct VestingSchedule {
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 totalAmount;
        uint256 releasedAmount;
    }

    mapping(address => VestingSchedule) public vestingSchedules;

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        paused = false;
        
    }
      // Define the isOperator function with appropriate visibility
    function isOperator(address account) public view returns (bool) {
        // Logic to determine if the account is an operator
        // Return true or false accordingly
    }

    function setStakingContract(address stakingContractAddress) external {
        require(address(_stakingContract) == address(0), "Staking contract already set");
        _stakingContract = Staking(stakingContractAddress);
    }

    function setMarketplaceContract(address marketplaceContractAddress) external {
        require(address(_marketplaceContract) == address(0), "Marketplace contract already set");
        _marketplaceContract = Marketplace(marketplaceContractAddress);
    }
    
    function setBiometricVerifierContract(address biometricVerifierAddress) external {
        require(address(_biometricVerifier) == address(0), "BiometricVerifier contract already set");
        _biometricVerifier = BiometricVerifier(biometricVerifierAddress);
    }
    
    function setSocialNetworkIdentificationContract(address socialNetworkIdentificationAddress) external {
        require(address(_socialNetworkIdentification) == address(0), "SocialNetworkIdentification contract already set");
        _socialNetworkIdentification = SocialNetworkIdentification(socialNetworkIdentificationAddress);
    }
    
    function setUserIdentityContract(address userIdentityAddress) external {
        require(address(_userIdentity) == address(0), "UserIdentity contract already set");
        _userIdentity = UserIdentity(userIdentityAddress);
    }

    modifier notPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    // Access Control Modifier
    modifier onlyAuthorized() {
        require(authorizedEntities[msg.sender], "Unauthorized access");
        _;
    }

    function pauseTokenTransfers(bool status) external {
        require(msg.sender == owner(), "Only the contract owner can pause token transfers");
        paused = status;
        emit Paused(status);
    }

    function transfer(address to, uint256 value) external notPaused returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Transfer amount must be greater than zero");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external notPaused returns (bool) {
        require(spender != address(0), "Invalid spender address");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external notPaused returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Transfer amount must be greater than zero");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Not allowed to spend this much");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) external notPaused returns (bool) {
        require(value > 0, "Burn amount must be greater than zero");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        totalSupply -= value;

        emit Burn(msg.sender, value);
        return true;
    }

    function mint(address to, uint256 value) external notPaused returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Mint amount must be greater than zero");
        require(msg.sender == owner(), "Only the contract owner can mint tokens");

        balanceOf[to] += value;
        totalSupply += value;

        emit Mint(to, value);
        return true;
    }

    function stake(uint256 amount) external notPaused {
        require(amount > 0, "Stake amount must be greater than zero");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        _stakingContract.stake(msg.sender, amount);

        emit Transfer(msg.sender, address(_stakingContract), amount);
    }

    function unstake(uint256 amount) external notPaused {
        require(amount > 0, "Unstake amount must be greater than zero");
        require(_stakingContract.isStaker(msg.sender), "Not a staker");
        require(_stakingContract.stakedBalanceOf(msg.sender) >= amount, "Insufficient staked balance");

        totalSupply += amount;
        balanceOf[msg.sender] += amount;
        _stakingContract.unstake(msg.sender, amount);

        emit Transfer(address(_stakingContract), msg.sender, amount);
    }

    function marketplaceTransfer(address to, uint256 value) external notPaused {
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Transfer amount must be greater than zero");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
    }

    function owner() internal view returns (address) {
        return address(this);
    }

    // Identity Mapping Functions

    // Only the authorized entities can set encrypted documents for a user
    function setEncryptedDocuments(address user, bytes32 encryptedData) external onlyAuthorized {
        encryptedDocuments[user] = encryptedData;
    }

    // Retrieve encrypted documents for a user (Only authorized entities can access this function)
    function getEncryptedDocuments(address user) external view onlyAuthorized returns (bytes32) {
        return encryptedDocuments[user];
    }

     // Authorize an entity to access specific identification data
    function authorizeEntity(address entity) external onlyAuthorized {
        authorizedEntities[entity] = true;
    }

    // Revoke access for an authorized entity
    function revokeAuthorization(address entity) external onlyAuthorized {
        authorizedEntities[entity] = false;
    }
}