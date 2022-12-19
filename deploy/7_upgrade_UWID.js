const contractName = 'UWIDUpgradeable';
const symbol = "UW";
const name = "University of Washington";

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();

	await deploy(contractName, {
		from: deployer,
		args: [name, symbol],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	});
}

func.tags = ['7'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func