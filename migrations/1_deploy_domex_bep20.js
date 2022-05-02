const fs = require('fs')
const domexBep20 = artifacts.require("DomexBep20");

module.exports = function (deployer) {
    deployer.deploy(domexBep20)
        .then(() => {
            if (domexBep20._json) {
                fs.writeFile('./deployed-files/domexBep20DeployedABI', JSON.stringify(domexBep20._json.abi), (err) => {
                    if (err) {
                        throw err
                    } else {
                        console.log("파일에 ABI 입력 성공")
                    }
                })
                
                fs.writeFile('./deployed-files/domexBep20DeployedAddress', domexBep20.address, (err) => {
                    if (err) {
                        throw err
                    } else {
                        console.log("파일에 주소 입력 성공")
                    }
                })
            }
        });
};