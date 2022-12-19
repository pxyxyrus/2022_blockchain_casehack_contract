const contractName = 'UWMajorUpgradeable';
const symbol = "UWCSE";
const name = "University of Washington Computer Science";

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();

	const UWIDContract = await deployments.get("UWID");

	await deploy(contractName, {
		from: deployer,
		args: [name, symbol, UWIDContract.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	});
}

func.tags = ['8'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func