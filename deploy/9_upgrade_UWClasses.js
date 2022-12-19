const contractName = 'UWClassesUpgradeable';
const quarterName = 'WIN2023';

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts, network } = hre;
	const { deploy } = deployments;

	const { deployer, simpleERC20Beneficiary } = await getNamedAccounts();

	const UWIDContract = await deployments.get("UWID");
}

func.tags = ['9'];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func