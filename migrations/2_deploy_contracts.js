var ConvertLib = artifacts.require("./ConvertLib.sol");
var Token = artifacts.require("./Token.sol");
var Climatecoin = artifacts.require("./Climatecoin.sol");

module.exports = function(deployer) {
  //deployer.deploy(ConvertLib);
  //deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(Climatecoin);
  deployer.deploy(Token);
};
