// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BiometricVerifier.sol";
import "./UserIdentity.sol";

contract UserVerification {
    BiometricVerifier private biometricVerifier;
    UserIdentity private userIdentity;

    mapping(address => bytes32) private hashedPasswords; // Step 1
    mapping(address => bool) private userConsents; // Step 7
    mapping(address => bool) private userRevocations; // Step 7
    mapping(address => bytes32) private facialRecognitionData; // Step 9

    event QRCodeGenerated(address indexed user, bytes32 qrCode);
    event UserRegistered(address indexed user);
    event UserConsentUpdated(address indexed user, bool consent);
    event UserRevocationUpdated(address indexed user, bool revoked);
    event FacialRecognitionDataRecorded(address indexed user, bytes32 facialData);

    modifier onlyVerifiedUser() {
        require(userIdentity.isIdentityVerified(msg.sender), "User identity not verified");
        _;
    }

    function verifyUserWithBiometrics(bytes32 biometricHash, bytes32 additionalBiometricData, bytes32 hashedPassword) external {
        require(address(biometricVerifier) != address(0), "BiometricVerifier contract not set");

        // Step 5: Perform biometric verification checks using the BiometricVerifier contract
        require(biometricVerifier.verifyBiometrics(msg.sender, biometricHash, additionalBiometricData), "Biometric verification failed");

        // Step 6: Perform MFA by comparing hashedPassword with the stored hashed password
        require(hashedPasswords[msg.sender] == hashedPassword, "Invalid hashed password");

        // Once the user is verified, generate a unique QR code
        bytes32 qrCode = generateQRCode(msg.sender);

        emit QRCodeGenerated(msg.sender, qrCode);
    }

    function generateQRCode(address user) internal view returns (bytes32) {
        // Step 9: Implement QR code generation logic here using cryptographic proofs of verified identity
        // Return the unique QR code
    }

    function setBiometricVerifierContract(address biometricVerifierAddress) external {
        biometricVerifier = BiometricVerifier(biometricVerifierAddress);
    }

    function setUserIdentityContract(address userIdentityAddress) external {
        userIdentity = UserIdentity(userIdentityAddress);
    }

    function registerUser(bytes32 hashedPassword) external {
        // Step 3: User registration
        require(hashedPassword != bytes32(0), "Invalid hashed password");
        require(!userIdentity.isIdentityVerified(msg.sender), "User identity is already verified");

        hashedPasswords[msg.sender] = hashedPassword;

        emit UserRegistered(msg.sender);
    }

    function validateUserData(bytes32 biometricHash, bytes32 additionalBiometricData) external view returns (bool) {
        // Step 4: User validation logic
        require(userIdentity.isIdentityVerified(msg.sender), "User identity not verified");

        // Required identity information
        string memory fullName = userIdentity.getUserFullName(msg.sender);
        uint256 dateOfBirth = userIdentity.getUserDateOfBirth(msg.sender);
        string memory nationality = userIdentity.getUserNationality(msg.sender);
        string memory addressData = userIdentity.getUserAddress(msg.sender);
        string memory phoneNumber = userIdentity.getUserPhoneNumber(msg.sender);

        // Optional information
        string memory emailAddress = userIdentity.getUserEmailAddress(msg.sender);
        string memory passportNumber = userIdentity.getUserPassportNumber(msg.sender);

        // Validation rules
        require(bytes(fullName).length > 0, "Full Name is required");
        require(dateOfBirth > 0, "Date of Birth is required");
        require(bytes(nationality).length > 0, "Nationality is required");
        require(bytes(addressData).length > 0, "Address is required");
        require(bytes(phoneNumber).length > 0, "Phone Number is required");

        require(bytes(fullName).length <= 100, "Full Name exceeds character limit");
        require(bytes(nationality).length <= 50, "Nationality exceeds character limit");
        require(bytes(addressData).length <= 200, "Address exceeds character limit");
        require(bytes(phoneNumber).length <= 20, "Phone Number exceeds character limit");

        // Validate Date of Birth
        require(dateOfBirth <= block.timestamp - 18 years, "User must be at least 18 years old");

        // Validate Nationality
        require(validateNationality(nationality), "Invalid nationality");

        // Additional data validation rules (customize as needed)
        // ...

        // Optional information validation
        if (bytes(emailAddress).length > 0) {
            require(validateEmail(emailAddress), "Invalid Email Address");
        }

        if (bytes(passportNumber).length > 0) {
            require(validatePassportNumber(passportNumber), "Invalid Passport Number");
        }

        // All data fields have passed validation
        return true;
    }

function validateNationality(string memory nationality) internal pure returns (bool) {
        // Step 4: Nationality validation logic
        // Example: Check against a list of valid nationalities
        // Customize this function according to your needs
        string[] memory validNationalities = getValidNationalities(); // Assume this function returns an array of valid nationalities
        bytes memory nationalityBytes = bytes(nationality);

        // Validate nationality length
        require(nationalityBytes.length >= 2 && nationalityBytes.length <= 50, "Invalid nationality length");

        for (uint256 i = 0; i < nationalityBytes.length; i++) {
            // Check if the nationality contains valid characters (letters and spaces only)
            require(isLetter(nationalityBytes[i]) || nationalityBytes[i] == 0x20, "Invalid nationality characters");
        }

        // Convert nationality to lowercase for case-insensitive comparison
        string memory lowerCaseNationality = toLowerCase(nationality);

        for (uint256 i = 0; i < validNationalities.length; i++) {
            // Compare the lowercase nationality with the lowercase valid nationalities
            if (compareStringsIgnoreCase(validNationalities[i], lowerCaseNationality)) {
                return true;
            }
        }
        return false;
    }

function isLetter(bytes1 b) internal pure returns (bool) {
    return (b >= 65 && b <= 90) || (b >= 97 && b <= 122);
}

   function isDigit(bytes1 b) internal pure returns (bool) {
    return b >= 48 && b <= 57;
}
function validateEmail(string memory email) internal pure returns (bool) {
    // Step 4: Email validation logic
    bytes memory emailBytes = bytes(email);

    // Validate email length
    require(emailBytes.length >= 5 && emailBytes.length <= 100, "Invalid email length");

    // Check for '@' symbol
    bool containsAtSymbol;
    for (uint256 i = 0; i < emailBytes.length; i++) {
        if (emailBytes[i] == 0x40) { // '@' symbol
            containsAtSymbol = true;
            break;
        }
    }
    require(containsAtSymbol, "Email must contain '@' symbol");

    // Check for '.' symbol after '@' symbol
    bool containsDotAfterAtSymbol;
    for (uint256 i = 0; i < emailBytes.length; i++) {
        if (emailBytes[i] == 0x40) { // '@' symbol
            for (uint256 j = i + 1; j < emailBytes.length; j++) {
                if (emailBytes[j] == 0x2E) { // '.' symbol
                    containsDotAfterAtSymbol = true;
                    break;
                }
            }
            break;
        }
    }
    require(containsDotAfterAtSymbol, "Email must contain '.' symbol after '@' symbol");

    // Check for valid characters (letters, digits, '@', '.', '-', '_', and '+')
    for (uint256 i = 0; i < emailBytes.length; i++) {
        require(isLetter(emailBytes[i]) || isDigit(emailBytes[i]) || emailBytes[i] == 0x40 || emailBytes[i] == 0x2E || emailBytes[i] == 0x2D || emailBytes[i] == 0x5F || emailBytes[i] == 0x2B, "Invalid email characters");
    }

    return true;
}

function validatePassportNumber(string memory passportNumber) internal pure returns (bool) {
    // Step 4: Passport number validation logic
   

    // The passport number must contain letters and digits and must be at least 6 characters long
    bytes memory passportBytes = bytes(passportNumber);

    // Validate passport number length
    require(passportBytes.length >= 6 && passportBytes.length <= 15, "Invalid passport number length");

    // Check for valid characters (letters and digits)
    for (uint256 i = 0; i < passportBytes.length; i++) {
        require(isLetter(passportBytes[i]) || isDigit(passportBytes[i]), "Invalid passport number characters");
    }

    return true;
}

// Helper function to convert a string to lowercase
function toLowerCase(string memory str) internal pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    for (uint256 i = 0; i < strBytes.length; i++) {
        // Convert uppercase letters to lowercase
        if (strBytes[i] >= 65 && strBytes[i] <= 90) {
            strBytes[i] = bytes1(uint8(strBytes[i]) + 32);
        }
    }
    return string(strBytes);
}

function compareStringsIgnoreCase(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(toLowerCase(a))) == keccak256(abi.encodePacked(toLowerCase(b)));
}

function getValidNationalities() internal pure returns (string[] memory) {
    // Replace this with your actual list of valid nationalities
    return ["USA", "Canada", "UK", "Germany", "France", "Spain", "China", "Japan", "India", "Australia"];
}


    function isIdentityVerified(address user) external view returns (bool) {
        // Step 2: Identity verification status
        return userIdentity.isIdentityVerified(user);
    }

    function updateUserConsent(bool consent) external {
        // Step 7: User consent management
        userConsents[msg.sender] = consent;
        emit UserConsentUpdated(msg.sender, consent);
    }

    function updateUserRevocation(bool revoked) external {
        // Step 7: User consent management
        userRevocations[msg.sender] = revoked;
        emit UserRevocationUpdated(msg.sender, revoked);
    }

    function recordFacialRecognitionData(bytes32 facialData) external onlyVerifiedUser {
        // Step 9: Advanced behavioral biometrics
        facialRecognitionData[msg.sender] = facialData;
        emit FacialRecognitionDataRecorded(msg.sender, facialData);
    }

    function verifyIdentityWithOracle(address user, bool isVerified) external {
        // Step 8: Identity verification oracle integration
        require(address(userIdentity) != address(0), "UserIdentity contract not set");
        userIdentity.verifyIdentity(user, isVerified);
    }

    function upgradeImplementation(address newImplementation) external {
        // Step 10: Smart contract upgradeability
        require(address(userIdentity) != address(0), "UserIdentity contract not set");
        require(msg.sender == userIdentity.owner(), "Only the owner can upgrade the implementation");
        userIdentity.upgradeImplementation(newImplementation);
    }
}
