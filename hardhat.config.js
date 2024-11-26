const requireOrMock = require("require-or-mock");
const localConfig = requireOrMock("local-config.js", {});

process.on('warning', (warning) => {
  console.log(warning.stack);
});

require("@nomicfoundation/hardhat-ethers");
// require("@nomiclabs/hardhat-waffle");
require("@xyrusworx/hardhat-solidity-json");

require("@nomicfoundation/hardhat-verify");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = Object.assign({
      solidity: {
        version: "0.8.22",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          }
        },
      },
    },
    localConfig
);
