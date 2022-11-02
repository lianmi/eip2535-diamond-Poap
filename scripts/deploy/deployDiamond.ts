import { ethers } from "hardhat"
import { getCutAdd, DiamondCut, deployFacet } from "../helpers"
import { executeCut } from "./_executeCut"

export async function deployDiamond(facetNames: string[], init = ''): Promise<string> {
  // get owner account
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]
  const addr1 = accounts[1]

  // deploy DiamondCutFacet
  const diamondCutFacet = await deployFacet('DiamondCutFacet')
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // deploy Diamond
  const poapName = "PoapSBTs";
  const uri = "https://sbts_poap.xyz/token/";
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address,poapName,poapName,uri,[addr1.address])
  await diamond.deployed()
  console.log('Diamond deployed:', diamond.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet', //系统默认
    'OwnershipFacet',    //系统默认
    ...facetNames        //自定义
  ]
  const cut: DiamondCut[] = []
  for (const FacetName of FacetNames) {
    const facet = await deployFacet(FacetName)
    console.log(`${FacetName} deployed: ${facet.address}`)

    const newCut = await getCutAdd(facet)
    cut.push(newCut)
  }

  // upgrade diamond with facets 
  // 首次也是这样进行初始化
  await executeCut(diamond.address, cut, init)

  return diamond.address
}
