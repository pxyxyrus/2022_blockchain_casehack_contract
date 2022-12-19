const contractName = 'UWMajorUpgradeable';
const symbol = "UWCSE";
const name = "University of Washington Computer Science";

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();

	const UWIDContract = await deployments.get("UWID");
}

func.tags = ['8'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func