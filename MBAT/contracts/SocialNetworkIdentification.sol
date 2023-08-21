// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BiometricVerifier.sol";
import "./UserIdentity.sol";
import "./MBATToken.sol";

contract SocialNetworkIdentification {
    struct UserProfile {
        string name;
        string email;
        string photoUrl;
        // Add any other relevant user profile data here
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => bytes32) private userActivityLog;
    mapping(address => address[]) private userFollowers;
    mapping(address => address[]) private userFollowing;
    mapping(address => bool) private userConnectionRequests;

    BiometricVerifier private biometricVerifier;
    UserIdentity private userIdentity;
    MBATToken private mbatToken;

    uint256 public qrCodeExpiryTime = 20; // Default QR code expiry time (in seconds)

    event UserProfileUpdated(address indexed user, string name, string email, string photoUrl);
    event QRCodeExpiryTimeUpdated(uint256 newExpiryTime);
    event UserActivityLogged(address indexed user, bytes32 activityHash);
    event UserFollowed(address indexed user, address indexed follower);
    event UserUnfollowed(address indexed user, address indexed follower);
    event ConnectionRequestSent(address indexed user, address indexed requester);
    event ConnectionRequestAccepted(address indexed user, address indexed accepter);

    modifier onlyVerifiedUser() {
        require(userIdentity.isIdentityVerified(msg.sender), "User identity not verified");
        _;
    }

    modifier onlyOperator() {
        require(mbatToken.isOperator(msg.sender), "Unauthorized operator");
        _;
    }

    function updateUserProfile(string memory name, string memory email, string memory photoUrl) external onlyVerifiedUser {
        userProfiles[msg.sender].name = name;
        userProfiles[msg.sender].email = email;
        userProfiles[msg.sender].photoUrl = photoUrl;

        emit UserProfileUpdated(msg.sender, name, email, photoUrl);
    }

    function setQRCodeExpiryTime(uint256 expiryTime) external onlyOperator {
        qrCodeExpiryTime = expiryTime;
        emit QRCodeExpiryTimeUpdated(expiryTime);
    }

    function logUserActivity(bytes32 activityHash) external onlyVerifiedUser {
        userActivityLog[msg.sender] = activityHash;
        emit UserActivityLogged(msg.sender, activityHash);
    }

    function getUserProfile(address user) external view returns (string memory name, string memory email, string memory photoUrl) {
        return (userProfiles[user].name, userProfiles[user].email, userProfiles[user].photoUrl);
    }

    function getUserActivityLog(address user) external view returns (bytes32) {
        return userActivityLog[user];
    }

    function clearUserActivityLog() external onlyVerifiedUser {
        delete userActivityLog[msg.sender];
    }

    function unfollowUser(address user) external onlyVerifiedUser {
        require(user != msg.sender, "Cannot unfollow yourself");

        address[] storage followers = userFollowers[user];
        for (uint256 i = 0; i < followers.length; i++) {
            if (followers[i] == msg.sender) {
                // Remove the follower from the list
                followers[i] = followers[followers.length - 1];
                followers.pop();
                break;
            }
        }

        address[] storage following = userFollowing[msg.sender];
        for (uint256 i = 0; i < following.length; i++) {
            if (following[i] == user) {
                // Remove the user from the following list
                following[i] = following[following.length - 1];
                following.pop();
                break;
            }
        }

        emit UserUnfollowed(user, msg.sender);
    }

    function acceptConnectionRequest(address requester) external onlyVerifiedUser {
        require(requester != msg.sender, "Cannot accept connection request from yourself");
        require(userConnectionRequests[msg.sender], "No connection request from this user");

        userConnectionRequests[msg.sender] = false;
        userFollowing[msg.sender].push(requester);
        userFollowers[requester].push(msg.sender);

        emit ConnectionRequestAccepted(msg.sender, requester);
    }

    function getFollowers(address user) external view returns (address[] memory) {
        return userFollowers[user];
    }

    function getFollowing(address user) external view returns (address[] memory) {
        return userFollowing[user];
    }

    function isConnectionRequestSent(address user) external view returns (bool) {
        return userConnectionRequests[user];
    }

    // Other functions to integrate external services for enhanced identification

    // Set contracts
    function setBiometricVerifierContract(address biometricVerifierAddress) external onlyOperator {
        biometricVerifier = BiometricVerifier(biometricVerifierAddress);
    }

    function setUserIdentityContract(address userIdentityAddress) external onlyOperator {
        userIdentity = UserIdentity(userIdentityAddress);
    }

    function setMBATTokenContract(address mbatTokenAddress) external onlyOperator {
        mbatToken = MBATToken(mbatTokenAddress);
    }
}
