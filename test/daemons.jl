### For simplicity we assume the same group to be ussed everywhere. 
G = CryptoGroups.MODP160Group()
Signature(data,signer) = DSASignature(hash("$data"),signer)

chash(envelopeA,envelopeB,key) = hash("$envelopeA $envelopeB $key")
id(s) = s.pubkey

function unwrap(envelope)
    data, signature = envelope
    @assert verify(signature,G)
    @assert signature.hash==hash("$data")
    return data, id(signature)
end

ballotkey = Signer(G)
gatekey = Signer(G)

#userids = Set()

user1key = Signer(G)
user2key = Signer(G)
user3key = Signer(G)

# push!(userids,hash(user1key.pubkey))
# push!(userids,hash(user2key.pubkey))
# push!(userids,hash(user3key.pubkey))

ballotmember = DH(data->(data,Signature(data,ballotkey)),envelope->envelope,G,chash,() -> rngint(100))
memberballot = DH(data->(data,nothing),unwrap,G,chash,() -> rngint(100))

ballotgate = DH(data->(data,Signature(data,ballotkey)),unwrap,G,chash,()->rngint(100))
gateballot = DH(data->(data,Signature(data,serverkey)),unwrap,G,chash,()->rngint(100))

membergate(memberkey) = DH(data->(data,Signature(data,memberkey)),unwrap,G,chash,() -> rngint(100))
gatemember = DH(data->(data,Signature(data,gatekey)),unwrap,G,chash,() -> rngint(100))

### The ballotbox server does:
bboxserver = BallotBox(2001,ballotgate,ballotmember,randperm)

### The gatekeeper does
gkserver = GateKeeper(2000,2001,3,gateballot,gatemember)

### Users do:

@async vote(2000,"msg1",membergate(user1key),memberballot,x -> Signature(x,user1key))
@async vote(2000,"msg2",membergate(user2key),memberballot,x -> Signature(x,user2key))
@async vote(2000,"msg3",membergate(user3key),memberballot,x -> Signature(x,user3key))

### After that gatekeeper gets ballot

@show take!(gkserver.ballots)

### Stopping stuff 
stop(bboxserver)
stop(gkserver)
