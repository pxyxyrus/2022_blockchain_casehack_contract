const contractName = 'UWIDUpgradeable';
const symbol = "UW";
const name = "University of Washington";

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();
}

func.tags = ['7'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func