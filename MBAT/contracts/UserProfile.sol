// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title UserProfile
 * @dev The UserProfile contract allows users to create and manage their profiles.
 * Users can store their personal information, such as name, email, profile photo, and more,
 * on the InterPlanetary File System (IPFS), providing full control over their data.
 */
contract UserProfile {
    struct Profile {
        string name;
        string email;
        string photo; // IPFS hash or link to the user's photo
        uint256 dateOfBirth;
        string nationality;
        string addressData;
        string phoneNumber;
        // Add more fields for identification details here
    }

    mapping(address => Profile) public profiles;
    mapping(string => address) private emailToAddress; // Ensure unique emails

    /**
     * @dev Emitted when a new profile is created.
     * @param user The address of the user creating the profile.
     * @param name The user's name.
     * @param email The user's email.
     */
    event ProfileCreated(address indexed user, string name, string email);

    /**
     * @dev Creates a user profile with the provided information.
     * @param name The user's name.
     * @param email The user's email.
     * @param photo IPFS hash or link to the user's photo.
     * @param dateOfBirth The user's date of birth.
     * @param nationality The user's nationality.
     * @param addressData The user's address.
     * @param phoneNumber The user's phone number.
     */
    function createProfile(
        string memory name,
        string memory email,
        string memory photo,
        uint256 dateOfBirth,
        string memory nationality,
        string memory addressData,
        string memory phoneNumber
    ) external {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(email).length > 0, "Email cannot be empty");
        require(bytes(photo).length > 0, "Photo cannot be empty");
        require(emailToAddress[email] == address(0), "Email is already used");

        profiles[msg.sender] = Profile(
            name,
            email,
            photo,
            dateOfBirth,
            nationality,
            addressData,
            phoneNumber
        );
        emailToAddress[email] = msg.sender;

        emit ProfileCreated(msg.sender, name, email);
    }

    /**
     * @dev Retrieves additional identification details from a user's profile.
     * @param user The address of the user.
     * @return dateOfBirth The user's date of birth.
     * @return nationality The user's nationality.
     * @return addressData The user's address.
     * @return phoneNumber The user's phone number.
     */
    function getIdentificationDetails(address user)
        external
        view
        returns (
            uint256 dateOfBirth,
            string memory nationality,
            string memory addressData,
            string memory phoneNumber
        )
    {
        Profile storage profile = profiles[user];
        return (
            profile.dateOfBirth,
            profile.nationality,
            profile.addressData,
            profile.phoneNumber
        );
    }
}
