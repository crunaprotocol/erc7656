const requireOrMock = require("require-or-mock");
const localConfig = requireOrMock("local-config.js", {});

process.on('warning', (warning) => {
  console.log(warning.stack);
});

require("@nomicfoundation/hardhat-ethers");
require("@xyrusworx/hardhat-solidity-json");
require("solidity-coverage");
require("@nomicfoundation/hardhat-verify");
require("@nomicfoundation/hardhat-chai-matchers");

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
