// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public tokenAddress; // every exchange allows swaps with only one token. v1은 이더랑만 교환 가능
    constructor(address _token){
        require(_token != address(0), "invalid token address");
        tokenAddress = _token;
    }

    // exchange에 유동성 주입하는 기능, payable이라 ether를 받을 수 있음.
    function addLiquidity(uint256 _tokenAmount) public payable {
        if(getReserve() == 0){ // 이 pool에 유동성이 없는 처음단계
            IERC20 token = IERC20(tokenAddress);
            // 받은 amount만큼 Exchange 컨트랙트에 토큰 가져오기
            token.transferFrom(msg.sender, address(this), _tokenAmount);
        }
        else{
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = msg.value * (tokenReserve / ethReserve); // 현재 토큰 비율에 맞게 인풋으로 들어온 이더로 토큰 양을 조절.
            require(_tokenAmount >= tokenAmount, "insufficient token amount");

            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);
        }
    }

    // eth-token pair 풀에서 그 token의 잔고 보여주기
    function getReserve() public view returns (uint256){
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //v1에서는 exchange contract is a price oracle.
    //price is simply a relation of reserves (Px = y/x, Py = x/y)
    function getPrice(uint256 inputReserve, uint256 outputReserve)
        public
        pure
        returns(uint256)
    {
        // 교환비를 구하는 두 토큰의 양 모두 0이 되면 안됨.
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        return (inputReserve*1000) / outputReserve; // x,y 둘다 구하고싶다면 함수를 각각 호출하면 됨. 그냥 나누면 소수점이 아니라 0이 나오므로 precision 추가
    }

    function getAmount(
        uint256 inputAmount, // 델타 x, 내가 넣는 인풋
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256){ // 리턴값은 델타y, 내가 받아야 하는 값
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        return (inputAmount*outputReserve) / (inputReserve + inputAmount);
        // y*dx / dx+x 를 코드로 작성.
    }

    // 인풋으로 최소 받아야하는 minToken 넣는다 => 근데 어떻게 넣지?
    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmount(
            msg.value, // 토큰 스왑하기 위해 받는 ether input
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");

        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    function tokenToEthSwap(uint256 _tokenSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokenSold, 
            tokenReserve, 
            address(this).balance);
        require(ethBought >= _minEth, "insufficient output amount");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);

    }
}