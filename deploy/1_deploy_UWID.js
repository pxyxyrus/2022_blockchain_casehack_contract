const contractName = 'UWID';
const symbol = "UW";
const name = "University of Washington";

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts } = hre;
	const { deploy } = deployments;
  
	const {deployer, simpleERC20Beneficiary} = await getNamedAccounts();


	await deploy(contractName, {
		from: deployer,
		args: [name, symbol],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	  });
}

func.tags = [contractName];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func