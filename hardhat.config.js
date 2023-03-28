require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
// require("hardhat-gas-reporter");
// require("solidity-coverage");

let fs = require('fs');
let privateKey;
privateKey = fs.readFileSync('./pk.txt', 'utf-8');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config = {
	defaultNetwork: "goerli",
	solidity: {
		version: "0.8.17",
		settings: {
			optimizer: {
				enabled: true,
				runs: 200
			}
		}
	},
	namedAccounts: {
		deployer: {
			default: 0
		}
	},
	paths: {
		sources: "./contracts",
		tests: "./test",
		cache: "./cache",
		artifacts: "./artifacts",
		deploy: "./deploy",
		deployments: "deployments",
		imports: "imports"
	},
	networks: {
		hardhat: {
			hardfork: 'merge',
			mining: {
				auto: true,
				interval: 1000
			},
			forking: {
				url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
			},
			chainId: 9999,
			gas: "auto",
			gasPrice: 18000000000
		},
		goerli: {
			url: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161",
			chainId: 5,
			accounts: [privateKey],
			// gas: "auto",
			// gasPrice: "auto",
			gas: "auto",
			gasPrice: 18000000000
		},
		ethmainnet: {
			url: "",
			chainId: 1,
			accounts: [privateKey],
			gas: "auto",
			gasPrice: "auto",
		}
	},
	// gasReporter: {
	// 	enabled: process.env.REPORT_GAS !== undefined,
	// 	currency: "USD",
	//   },
	//   etherscan: {
	// 	apiKey: process.env.ETHERSCAN_API_KEY,
	//   },
};

module.exports = config;