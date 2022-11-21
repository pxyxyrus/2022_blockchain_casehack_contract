const contractName = 'UWClasses';
const quarterName = 'WIN2023';

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts } = hre;
	const { deploy } = deployments;
  
	const {deployer, simpleERC20Beneficiary} = await getNamedAccounts();
    
	const UWIDContract = await deployments.get("UWID");

	await deploy(contractName, {
		from: deployer,
		args: [UWIDContract.address, quarterName],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	});
}

func.tags = [contractName];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func