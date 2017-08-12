var Campaign = artifacts.require("./Campaign.sol");
var FDRToken = artifacts.require("./FDRToken.sol");

module.exports = function(deployer) {
  deployer.deploy(Campaign);
  deployer.link(Campaign, FDRToken);
  deployer.deploy(FDRToken);
};
