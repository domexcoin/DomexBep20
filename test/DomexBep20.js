const DomexBep20 = artifacts.require("DomexBep20");

contract("DomexBep20", (accounts) => {
    it("첫 계정에 1000 DomexToken 넣기", async () => {
        const instance = await DomexBep20.deployed();
        
        const zeroAccountBalance = await instance.balanceOf.call(accounts[0]);
        
        assert.equal(zeroAccountBalance.valueOf(), 1000, "1000 wasn't in the first account");
    });
});