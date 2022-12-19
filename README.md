# 2022 UW Blockchain Case Hack
## UW Registration with NFTs

The smart contracts were deployed in the Goerli testnet

```json

Non Upgradeable Versions
"Owner": "0x2391EeCb0D2eBB8ef165477beB3b9BdFFE8E6b9d"

"UWID": "0xA334C78Ce1c3a7DC5623e631b57aa3dCCd0A1616"

"UWMajor(CSE)": "0xa80ab75013F6fc52d038FE9f0A335a6CbD3Dc9FF"

"UWClasses": "0xF2D8ffE5D1EfeCD4B52b57b7B6c0f632d6CBd5F6"



Upgradeables

"UWIDUpgradeable": "0xdE28D3DC3939696cB1A3AF579638a3Bcd200a025"

"UWIDProxy": "0x0dA9caF0b1884f8Ac843A348Ae396Bea28B4c003"

"UWMajorUpgradeable": "0xC5807c25Ac779235a3D1e55d4D7b428E5033Ac60"

"UWCSEProxy": "0x163BBDB2e13418d170169477df62376a95ea4597"

"UWClassesUpgradeable": "0x99baFCbAc29Ba6D5cb5D1BbbCd51384EeD40B3f6"

"UWClassesProxy": "0xc2bb81038b8b868175822a7e34c0a31E51b3fAb9"

```

### UWID(ERC-721)
* The token id represents the student number.
* The minting and burning are done by the contract owner, which is UW.
* Only one UWID can be owned per account.
* Transferring is not allowed.

### UWMajor(ERC-721)
* This NFT represents the UW majors.
* It can only be minted to accounts that own the UWID NFT.
* When minted, the token ID is set to the same token ID of UWID.
The minting and burning are done by the contract owner, which is UW.
* The token name and symbol represent the major name and the abbreviation.
Ex) token name: University of Washington Computer Science
token symbol: UWCSE
* Transferring is not allowed.
* Can only own one NFT of the same major.

### UWClasses(ERC-1155)
* The token ID represents the class SLN.
* Student accounts that own the UWID NFT are only allowed to register(mint) and drop(burn) classes.
* Some classes require the account to own a specific UWMajor NFT. 
* Transferring is allowed.
* Registration periods, major restrictions, class availability, time conflicts, and credit limits are implemented. 
* The uri function shows the class information on the UW time schedule page.
