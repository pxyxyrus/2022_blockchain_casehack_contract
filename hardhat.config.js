require("@nomicfoundation/hardhat-toolbox");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("solidity-coverage");

let fs = require('fs');
let privateKey;
privateKey = fs.readFileSync('./pk.txt', 'utf-8');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config = {
	defaultNetwork: "hardhat",
	solidity: {
		version: "^0.8.0",
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
				auto: false,
				interval: 0
			},
			forking: {
				url: "https://goerli.infura.io/v3/",
			},
			chainId: 1,
			gasPrice: 0,
		},
		goreli: {
			url: "https://goerli.infura.io/v3/",
			chainId: 5,
			accounts: [privateKey],
		},
		ethmainnet: {
			url: "",
			chainId: 1,
			accounts: [privateKey],
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

// module.exports = {
//   defaultNetwork: "hardhat",
//   networks: {
//     hardhat: {
//       hardfork: 'merge',
//       mining: {
//         auto: false,
//         interval: 0
//       },
//       forking: {
//         url: "https://goerli.infura.io/v3/",
//       },
//       chainId: 1,
//       gasPrice: 0,
//     },
//     goreli: {
//       url: "https://goerli.infura.io/v3/",
//       chainId: 5,
//       accounts: [privateKey],
//     },
//     ethmainnet: {
//       url: "",
//       chainId: 1,
//       accounts: [privateKey],
//     }
//   },
//   solidity: {
//     version: "0.8.17",
//     settings: {
//       optimizer: {
//         enabled: true,
//         runs: 200
//       }
//     }
//   },
//   paths: {
//     sources: "./contracts",
//     tests: "./test",
//     cache: "./cache",
//     artifacts: "./artifacts"
//   },
//   mocha: {
//     timeout: 40000
//   }
// }
