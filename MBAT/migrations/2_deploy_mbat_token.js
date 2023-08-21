// 2_deploy_mbat_token.js
const MBATToken = artifacts.require("MBATToken");

module.exports = function (deployer) {
  // Set the initial supply to one billion tokens (1,000,000,000)
  const initialSupply = 1000000000 * (10 ** 18); // One billion tokens with 18 decimal places

  // Deploy MBATToken contract with the specified initial supply
  deployer.deploy(MBATToken, initialSupply);
};