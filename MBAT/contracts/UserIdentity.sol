// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserIdentity {
    struct Identity {
        address userAddress;
        bool isVerified;
        uint256 verificationTime;
        bytes32 qrCode; // Cryptographic proof of verified identity
        string fullName;
        uint256 dateOfBirth;
        string nationality;
        string addressData;
        string phoneNumber;
        string emailAddress;
        string passportNumber;
        // Add more fields as needed
    }

    mapping(address => Identity) public identities;
    mapping(bytes32 => address) private qrCodeToAddress; // Ensure unique QR codes

    event IdentityVerified(address indexed user, bytes32 qrCode);
    event UserFullNameUpdated(address indexed user, string fullName);
    event UserDateOfBirthUpdated(address indexed user, uint256 dateOfBirth);
    event UserNationalityUpdated(address indexed user, string nationality);
    event UserAddressUpdated(address indexed user, string addressData);
    event UserPhoneNumberUpdated(address indexed user, string phoneNumber);
    event UserEmailAddressUpdated(address indexed user, string emailAddress);
    event UserPassportNumberUpdated(address indexed user, string passportNumber);

    function verifyIdentity(
        bytes32 qrCode,
        string memory fullName,
        uint256 dateOfBirth,
        string memory nationality,
        string memory addressData,
        string memory phoneNumber,
        string memory emailAddress,
        string memory passportNumber
    ) external {
        require(!identities[msg.sender].isVerified, "User identity already verified");
        require(qrCodeToAddress[qrCode] == address(0), "QR code is already used");

        // Additional validation checks for user data (optional)
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
        require(dateOfBirth <= block.timestamp - 18 * 365 days, "User must be at least 18 years old");

        // Validate Nationality (optional)
        require(bytes(nationality).length > 0, "Nationality is required");
        require(bytes(nationality).length <= 50, "Nationality exceeds character limit");

        identities[msg.sender] = Identity({
            userAddress: msg.sender,
            isVerified: true,
            verificationTime: block.timestamp,
            qrCode: qrCode,
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            nationality: nationality,
            addressData: addressData,
            phoneNumber: phoneNumber,
            emailAddress: emailAddress,
            passportNumber: passportNumber
        });
        qrCodeToAddress[qrCode] = msg.sender;

        emit IdentityVerified(msg.sender, qrCode);
    }
    function isIdentityVerified(address user) external view returns (bool) {
        return identities[user].isVerified;
    }

    function getUserFullName(address user) external view returns (string memory) {
        return identities[user].fullName;
    }

    function getUserDateOfBirth(address user) external view returns (uint256) {
        return identities[user].dateOfBirth;
    }

    function getUserNationality(address user) external view returns (string memory) {
        return identities[user].nationality;
    }

    function getUserAddress(address user) external view returns (string memory) {
        return identities[user].addressData;
    }

    function getUserPhoneNumber(address user) external view returns (string memory) {
        return identities[user].phoneNumber;
    }

    function getUserEmailAddress(address user) external view returns (string memory) {
        return identities[user].emailAddress;
    }

    function getUserPassportNumber(address user) external view returns (string memory) {
        return identities[user].passportNumber;
    }

    function updateFullName(string memory fullName) external {
        // Validate Full Name (optional)
        require(bytes(fullName).length > 0, "Full Name is required");
        require(bytes(fullName).length <= 100, "Full Name exceeds character limit");

        identities[msg.sender].fullName = fullName;
        emit UserFullNameUpdated(msg.sender, fullName);
    }

    function updateDateOfBirth(uint256 dateOfBirth) external {
        // Validate Date of Birth (optional)
        require(dateOfBirth > 0, "Date of Birth is required");
        require(dateOfBirth <= block.timestamp -  18 * 365 days, "User must be at least 18 years old");

        identities[msg.sender].dateOfBirth = dateOfBirth;
        emit UserDateOfBirthUpdated(msg.sender, dateOfBirth);
    }

    function updateNationality(string memory nationality) external {
        // Validate Nationality (optional)
        require(bytes(nationality).length > 0, "Nationality is required");
        require(bytes(nationality).length <= 50, "Nationality exceeds character limit");

        identities[msg.sender].nationality = nationality;
        emit UserNationalityUpdated(msg.sender, nationality);
    }

    function updateAddress(string memory addressData) external {
        // Validate Address (optional)
        require(bytes(addressData).length > 0, "Address is required");
        require(bytes(addressData).length <= 200, "Address exceeds character limit");

        identities[msg.sender].addressData = addressData;
        emit UserAddressUpdated(msg.sender, addressData);
    }

    function updatePhoneNumber(string memory phoneNumber) external {
        // Validate Phone Number (optional)
        require(bytes(phoneNumber).length > 0, "Phone Number is required");
        require(bytes(phoneNumber).length <= 20, "Phone Number exceeds character limit");

        identities[msg.sender].phoneNumber = phoneNumber;
        emit UserPhoneNumberUpdated(msg.sender, phoneNumber);
        }

    function updateEmailAddress(string memory emailAddress) external {
        identities[msg.sender].emailAddress = emailAddress;
        emit UserEmailAddressUpdated(msg.sender, emailAddress);
    }

    function updatePassportNumber(string memory passportNumber) external {
        identities[msg.sender].passportNumber = passportNumber;
        emit UserPassportNumberUpdated(msg.sender, passportNumber);
    }

 
}