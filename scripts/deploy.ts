const hre = require("hardhat");

async function main() {
    const deployedContract = await hre.ethers.deployContract("GrowthUP");
    await deployedContract.waitForDeployment();
    console.log(
        `Counter contract deployed to https://zkatana.blockscout.com/address/${deployedContract.target}`
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});