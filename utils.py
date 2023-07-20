from web3 import Web3

def tokenIdentifierGetter(creatorAddress,tokenIndexNo, amount):
    assert Web3.isAddress(creatorAddress), "incorrect creator address"

    binaryCreatorAddress = bin(int(creatorAddress, 16))[2:].zfill(160)

    binaryTokenId = bin(tokenIndexNo)[2:].zfill(56)

    binaryAmount = bin(amount)[2:].zfill(40)

    binaryString = binaryCreatorAddress + binaryTokenId + binaryAmount
    hexTokenIdentifier = hex(int(binaryString, 2))

    return hexTokenIdentifier


creator = '0xBCB97D08DEaCE92B11E7E48A825A655cA5493060'
tokenIndexNo = 1
amount = 30

hexTokenIdentifier = tokenIdentifierGetter(creator,tokenIndexNo,amount)
print(int(hexTokenIdentifier,16),hexTokenIdentifier)