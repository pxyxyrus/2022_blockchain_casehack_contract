const contractName = 'Test';
// const tokenName = 'Embody';
// const tokenSymbol = 'EMBODY';

// const imxContractAddress = '0x4527be8f31e2ebfbef4fcaddb5a17447b27d2aef';

const func = async (hre) => {
	const { deployments, getNamedAccounts, getUnnamedAccounts } = hre;
	const { deploy } = deployments;
  
	const {deployer, simpleERC20Beneficiary} = await getNamedAccounts();


	await deploy(contractName, {
		from: deployer,
		args: [],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	  });
}

func.tags = [contractName];
// func.id = ;
// func.dependencies = [];
// func.runAtTheEnd = true;

module.exports = func