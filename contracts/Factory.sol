pragma solidity ^0.8.0;

import "./Exchange.sol";

contract Factory {
    mapping(address => address) public tokenToExchange;

    function createExchange(address _tokenAddress) public returns (address){
        require(_tokenAddress != address(0), "invalid token Address");
        require(tokenToExchange[_tokenAddress] == address(0), "exchange already exists");

        Exchange exchange = new Exchange(_tokenAddress); //Exchange 컨트랙트 생성
        tokenToExchange[_tokenAddress] = address(exchange);
        return address(exchange);
    }

    function getExchange(address _tokenAddress) public view returns (address){
        return tokenToExchange[_tokenAddress];
    }
}