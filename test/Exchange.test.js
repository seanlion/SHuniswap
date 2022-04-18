require("@nomiclabs/hardhat-waffle");
const { expect } = require("chai");

// ether -> Wei로 변환
const toWei = (value) => ethers.utils.parseEther(value.toString());

// Wei > ether로 변환
const fromWei = (value) =>
  ethers.utils.formatEther(
    typeof value === "string" ? value : value.toString()
  );

//계정 잔고 확인
const getBalance = ethers.provider.getBalance;

describe("Exchange", () => {
  let owner;
  let user;
  let exchange;

  beforeEach(async () => {
    [owner, user] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("Token");
    token = await Token.deploy("Token", "TKN", toWei(1000000));
    await token.deployed();

    const Exchange = await ethers.getContractFactory("Exchange");
    exchange = await Exchange.deploy(token.address);
    await exchange.deployed();
  });

  it("is deployed", async () => {
    expect(await exchange.deployed()).to.equal(exchange);
  });

  describe("addLiquidity", async () => {
    it("adds liquidity", async () => {
      await token.approve(exchange.address, toWei(200));
      //transferFrom에 대한 value 설정. 앞의 200은 token 개수, 뒤에 100은 이더 개수
      // 이러면 그 ERC20 token 컨트랙트에 토큰 200개 보내고, Exchange 컨트랙트에는 이더 100개를 보내게 됨.
      await exchange.addLiquidity(toWei(200), { value: toWei(100) });
      // exchange 컨트랙트가 갖고있는 balance = 100 이더
      expect(await getBalance(exchange.address)).to.equal(toWei(100));
      expect(await exchange.getReserve()).to.equal(toWei(200));
    });
  });

  describe("getPrice", async () => {
    it("returns correct prices", async () => {
      await token.approve(exchange.address, toWei(2000));
      await exchange.addLiquidity(toWei(2000), { value: toWei(1000) });

      const tokenReserve = await exchange.getReserve();
      const etherReserve = await getBalance(exchange.address);

      // 1토큰 당 이더 가격 구하기(1000을 곱한 결과가 필요)
      expect( (await exchange.getPrice(etherReserve, tokenReserve)).toString()).to.eq("500");
      // 1이더 당 토큰 가격 구하기(1000을 곱한 결과가 필요)
      expect( (await exchange.getPrice(token, etherReserve)).toString()).to.eq("2000");
    })
  });
});