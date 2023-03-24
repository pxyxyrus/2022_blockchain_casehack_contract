const proxyContractName = 'TransparentUpgradeableProxy';
const proxyName = 'UWIDProxy';
const contractName = 'UWIDUpgradeable';
const symbol = "UW";
const name = "University of Washington";
const _Web3 = require('web3');
const web3 = new _Web3();

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();

	const implementation = await deploy(contractName, {
		from: deployer,
		args: [],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	});

	// function selector for the init function
	const initSig = '__UWID_init(string,string)';
	// function signature
	const initHex = web3.eth.abi.encodeFunctionSignature(initSig)
		+ web3.eth.abi.encodeParameters(['string', 'string'], [name, symbol]).substring(2);

	const proxy = await deploy(proxyName, {
		from: deployer,
		contract: proxyContractName,
		args: [implementation.address, deployer, initHex],
		log: true,
		autoMine: true
	});
}

func.tags = ['4'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func