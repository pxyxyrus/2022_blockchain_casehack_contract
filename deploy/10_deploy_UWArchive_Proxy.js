const proxyContractName = 'TransparentUpgradeableProxy';
const proxyName = 'UWArchiveProxy';
const contractName = 'UWArchiveUpgradeable';
const quarterName = 'WIN2023';
const _Web3 = require('web3');
const web3 = new _Web3();

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();

	const UWIDProxy = await deployments.get("UWIDProxy");

	const implementation = await deploy(contractName, {
		from: deployer,
		contract: contractName,
		args: [],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	});

	// function signature
	const initSig = '__UWArchive_init(address)';
	// function selector for the init function
	const initHex = web3.eth.abi.encodeFunctionSignature(initSig)
		+ web3.eth.abi.encodeParameters(['address'], [UWIDProxy.address]).substring(2);

	const proxy = await deploy(proxyName, {
		from: deployer,
		contract: proxyContractName,
		args: [implementation.address, deployer, initHex],
		log: true,
		autoMine: true
	});
}

func.tags = ['6'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func