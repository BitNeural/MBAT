// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract BiometricVerifier {

    enum OperatorRole { Admin, Supervisor, Operator }
    struct BiometricData {
        bytes32 biometricHash;
        bytes32 additionalBiometricData; // Renamed: Additional biometric data (e.g., fingerprint, iris scan)
        uint256 enrollmentTime;
        bool isAlive;
        bytes32 behavioralData;
        uint256 verificationCount;
        bool isVerified;
        bool isSuspended;
        string name;
        string addr;
        mapping(uint256 => bool) verificationHistory;
    }

    mapping(address => BiometricData) public biometricData;
    mapping(address => OperatorRole) public operators;

    uint256 public verificationThreshold = 3;
    uint256 public verificationCooldown = 1 days;

    event BiometricEnrollment(address indexed user, bytes32 biometricHash, uint256 enrollmentTime);
    event LivenessDetectionResult(address indexed user, bool isAlive);
    event BehavioralBiometricsRecorded(address indexed user, bytes32 behavioralData);
    event UserVerified(address indexed user);
    event BiometricDataRevoked(address indexed user);
    event OperatorAdded(address indexed operator, OperatorRole role);
    event OperatorRemoved(address indexed operator);
    event UserSuspended(address indexed user, bool suspended);
    event OperatorSuspended(address indexed operator, bool suspended);
    event VerificationAttempt(address indexed operator, address indexed user, bool success);
    event BiometricDataUpdated(address indexed user, bytes32 biometricHash, bytes32 biometricData, string name, string addr);
    event OperatorActivityRecorded(address indexed operator, string activity);
    event UserActivityRecorded(address indexed user, string activity);

    // New: Reputation system
    mapping(address => uint256) public operatorReputation;
    mapping(address => uint256) public userReputation;

    // New: Biometric data encryption
    mapping(address => bytes) private encryptedBiometricData;

    // New: Multi-factor authentication
    mapping(address => bytes32) private passwordHash; // Assuming password is hashed and stored securely off-chain

    // New: Smart contract upgradeability
    address public implementation; // Proxy contract address

    // New: Advanced Behavioral Biometrics
    mapping(address => bytes32) private facialRecognitionData;

    // New: Identity verification oracles
    mapping(address => bool) private isVerifiedIdentity;

    // New: Incentive Mechanism
    mapping(address => uint256) public tokenRewards;

    modifier onlyOperator() {
        require(operators[msg.sender] == OperatorRole.Admin || operators[msg.sender] == OperatorRole.Supervisor || operators[msg.sender] == OperatorRole.Operator, "Unauthorized operator");
        require(!biometricData[msg.sender].isSuspended, "User is suspended");
        _;
    }

    modifier onlyAdmin() {
        require(operators[msg.sender] == OperatorRole.Admin, "Only admin can call this function");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "You are not the owner of this data");
        _;
    }

    function setVerificationThreshold(uint256 threshold) external onlyAdmin {
        verificationThreshold = threshold;
    }

    function setVerificationCooldown(uint256 cooldown) external onlyAdmin {
        verificationCooldown = cooldown;
    }

    function addOperator(address operator, OperatorRole role) external onlyAdmin {
        operators[operator] = role;
        emit OperatorAdded(operator, role);
    }

    function removeOperator(address operator) external onlyAdmin {
        delete operators[operator];
        emit OperatorRemoved(operator);
    }

    function enrollBiometric(bytes32 biometricHash, bytes32 additionalBiometricData, string memory name, string memory addr, bytes32 hashedPassword) external {
        require(biometricHash != bytes32(0), "Invalid biometric hash");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(addr).length > 0, "Address cannot be empty");

        biometricData[msg.sender].biometricHash = biometricHash;
        biometricData[msg.sender].additionalBiometricData = additionalBiometricData; // Updated: Store additional biometric data
        biometricData[msg.sender].enrollmentTime = block.timestamp;
        biometricData[msg.sender].name = name;
        biometricData[msg.sender].addr = addr;

        // New: Save the hashed password for multi-factor authentication
        passwordHash[msg.sender] = hashedPassword;

        emit BiometricEnrollment(msg.sender, biometricHash, block.timestamp);
    }

    function performLivenessDetection(bool isAlive) external onlyOperator {
        biometricData[msg.sender].isAlive = isAlive;
        emit LivenessDetectionResult(msg.sender, isAlive);
    }

    function recordBehavioralBiometrics(bytes32 behavioralData) external onlyOperator {
        biometricData[msg.sender].behavioralData = behavioralData;
        emit BehavioralBiometricsRecorded(msg.sender, behavioralData);
    }

    function verifyUser(address user) external onlyOperator {
        require(bytes(biometricData[user].name).length > 0, "User not enrolled");
        require(biometricData[user].isAlive, "Liveness not confirmed");
        require(!biometricData[user].isSuspended, "User is suspended");

        uint256 lastVerificationTime = getLastVerificationTime(user);
        require(block.timestamp >= lastVerificationTime + verificationCooldown, "Verification cooldown not met");

        biometricData[user].verificationCount++;
        biometricData[user].verificationHistory[block.timestamp] = true; // Successful verification
        if (biometricData[user].verificationCount >= verificationThreshold) {
            biometricData[user].isVerified = true;
            emit UserVerified(user);
        }

        // New: Increment operator's reputation
        operatorReputation[msg.sender]++;

        // New: Increment user's reputation
        userReputation[user]++;

        // New: Grant token rewards to operators and users
        tokenRewards[msg.sender]++;
        tokenRewards[user]++;

        emit VerificationAttempt(msg.sender, user, true);
    }

    function revokeBiometricData() external onlyOwner {
        delete biometricData[msg.sender];
        emit BiometricDataRevoked(msg.sender);
    }

    function isUserVerified(address user) external view returns (bool) {
        return biometricData[user].isVerified;
    }

    function getLastVerificationTime(address user) public view returns (uint256) {
        uint256 lastVerificationTime = biometricData[user].enrollmentTime;
        for (uint256 i = lastVerificationTime + verificationCooldown; i < block.timestamp; i += verificationCooldown) {
            if (biometricData[user].verificationHistory[i]) {
                lastVerificationTime = i;
            }
        }
        return lastVerificationTime;
    }
    
    // New: Verify biometrics for a user
    function verifyBiometrics(
        address user,
        bytes32 biometricHash,
        bytes32 additionalBiometricData
    ) external view returns (bool) {
        require(biometricData[user].enrollmentTime > 0, "User not enrolled");
        require(biometricData[user].isAlive, "Liveness not confirmed");
        require(!biometricData[user].isSuspended, "User is suspended");

        // Compare provided biometricHash with stored biometricHash
        if (biometricData[user].biometricHash != biometricHash) {
            return false;
        }

        // Compare provided additionalBiometricData with stored additionalBiometricData
        if (biometricData[user].additionalBiometricData != additionalBiometricData) {
            return false;
        }

        return true;
    }

    function suspendUser(address user, bool suspend) external onlyAdmin {
        biometricData[user].isSuspended = suspend;
        emit UserSuspended(user, suspend);
    }

    function suspendOperator(address operator, bool suspend) external onlyAdmin {
        require(operators[operator] != OperatorRole.Admin, "Cannot suspend admin");
        biometricData[operator].isSuspended = suspend;
        emit OperatorSuspended(operator, suspend);
    }

    function updateBiometricData(bytes32 newBiometricHash, bytes32 newAdditionalBiometricData, string memory newName, string memory newAddr, bytes32 hashedPassword) external onlyOwner {
        require(newBiometricHash != bytes32(0), "Invalid biometric hash");
        require(bytes(newName).length > 0, "Name cannot be empty");
        require(bytes(newAddr).length > 0, "Address cannot be empty");
        require(biometricData[msg.sender].enrollmentTime > 0, "User not enrolled");
        require(!biometricData[msg.sender].isSuspended, "User is suspended");

        require(biometricData[msg.sender].biometricHash == newBiometricHash, "New biometric hash does not match the original");

        biometricData[msg.sender].biometricHash = newBiometricHash;
        biometricData[msg.sender].additionalBiometricData = newAdditionalBiometricData; // Updated: Update additional biometric data
        biometricData[msg.sender].name = newName;
        biometricData[msg.sender].addr = newAddr;

        // New: Update hashed password for multi-factor authentication
        passwordHash[msg.sender] = hashedPassword;

        emit BiometricDataUpdated(msg.sender, newBiometricHash, newAdditionalBiometricData, newName, newAddr);
    }

    // New: Record facial recognition data for users
    function recordFacialRecognitionData(bytes32 facialData) external onlyOperator {
        facialRecognitionData[msg.sender] = facialData;
    }

    // New: Connect to external identity verification oracles
    function verifyIdentity(address user, bool isVerified) external onlyAdmin {
        isVerifiedIdentity[user] = isVerified;
    }


    // New: Smart contract upgradeability
    function upgradeImplementation(address newImplementation) external onlyAdmin {
        implementation = newImplementation;
    }

    // New: Record operator activity for auditing purposes
    function recordOperatorActivity(string memory activity) external onlyOperator {
        emit OperatorActivityRecorded(msg.sender, activity);
    }

    // New: Record user activity, such as data updates or revocation
    function recordUserActivity(string memory activity) external {
        require(biometricData[msg.sender].enrollmentTime > 0, "User not enrolled");
        emit UserActivityRecorded(msg.sender, activity);
    }

    function owner() internal view returns (address) {
        return address(this);
    }
}



    