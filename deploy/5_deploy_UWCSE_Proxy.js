const proxyContractName = 'TransparentUpgradeableProxy';
const proxyName = 'UWCSEProxy';
const contractName = 'UWMajorUpgradeable';
const symbol = "UWCSE";
const name = "University of Washington Computer Science";
const _Web3 = require('web3');
const web3 = new _Web3();

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();

	const UWIDProxy = await deployments.get("UWIDProxy");

	const implementation = await deploy(contractName, {
		from: deployer,
		args: [],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	});


	// function signature
	const initSig = '__UWMajor_init(string,string,address)';
	// function selector for the init function
	const initHex = web3.eth.abi.encodeFunctionSignature(initSig)
		+ web3.eth.abi.encodeParameters(['string', 'string', 'address'], [name, symbol, UWIDProxy.address]).substring(2);

	const proxy = await deploy(proxyName, {
		from: deployer,
		contract: proxyContractName,
		args: [implementation.address, deployer, initHex],
		log: true,
		autoMine: true
	});
}

func.tags = ['5'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func