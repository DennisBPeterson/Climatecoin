pragma solidity >=0.4.13;

import "truffle/Assert.sol";
import "../contracts/Token.sol";

contract TestToken {

  function testInitialBalanceWithNewToken() {
    Token tok = new Token();
    Assert.equal(tok.balanceOf(this), 0, "balance");
  }

}
