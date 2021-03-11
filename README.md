# a-dens

Decentralized Name Service for Free TON Blockhain

## Summary

Decentralized name service implementation according to the DeNS Contest Paper [2] and excellent TIP-2 Decentralized Certificates (DeCert) [3]

# Architecture

## Domains

System functionality divided into following domains:

- NIC - name identity certificate to keep registered name details
- DeNSRoot - registration and NIC auction management
- Auction - NIC auction implementation
- SMV management - Soft Majority Voting alternative to manage reserved NICs
- DeBot Interfaces - Interface with the user interaction scenarios

## System actors

- DeNSRoot owner (also referred as root owner)  - deploys and manages DeNSRoot smart contract, own key pair owner.
- DeNSRoot smart contract (root sc) - coordinates NIC issue and resolving processes, controls NIC validity, manages NIC auctions, provides SMV interface for reserved names.
- Resolver (resolver)  - retrieve NIC information.
- NIC smart contract (nic sc) - store, change and retrieve NIC information.
- NIC owner (nic owner) - NIC information provider identified by signature or/and address.
- NIC bidder (nic bidder) - Auction bidder. The highest auction bidder will be transformed to the nic owner for the owning timespan.
- Auction smart contract (auction sc) - controls action process related to a particular NIC name.

## Use Cases

### Name resolution

1. Resolver obtains from trusted sources root sc address.
2. Resolver optionally checks the code of root sc contract.
3. Resolver uses resolve method to get registered address and expiration date.
4. Resolver uses nic sc getNICxxx methods to obtain associated information.
5. Resolver can optionally cache information obtained in step 3 within the validity period.
6. Another option is to retrieve NIC code and root sc address to calculate name address.

### DeNSRoot creation

This use case has two variants. Firstly root sc can be deployed using code, root owner private key and constructor parameters. 
Secondly root sc can be deployed as part of hierarchical name issue process.
Latter case assumes that another root sc will be deployed for subsequent names of the hierarchical name and corresponded address will appear in linked nic sc.

1. Root owner calculates the new address of the root sc.
2. Root owner transfers some funds to the address calculated.
3. Root owner collects root sc constructor parameters and deploys the root sc.

### NIC Name registration

1. NIC bidder calls calculateBidHash getter method of the root sc ans supplies bid hash and seed.
2. NIC bidder calls regName with NIC name, years to own the name and bid hash calculated earlier.
3. Root sc will start auction with sc if NIC sc for that name does not exists or will expire in next 28 days.
4. NIC bidder can query auction using auction address calculated by root sc.
5. NIC bidder can pay the bid price if auction is in the collect phase.
6. NIC bidder address will become next NIC name owner for the requested number of years if highest payed bid.
7. New NIC owner will receive difference between the payed bid and second highest bid.
8. All other NIC bidder payed bids will be returned to the owners.

### NIC Name management

1. NIC Owner change mutable NIC information in granted owning period.
2. NIC Owner can deploy new root sc and set 'm_root_sc' member to manage hierarchy NIC names.

# Environment requirements

1. Use Arch linux (tested), Debian, Ubuntu or other linux distro. 
2. tonos-cli, tvmlinker and obvious utilities should be present. 
3. (opt) use tondev for local deployment

# Dev Environment

1. install and run tondev se
2. rename env-template.sh to env.sh and change it to suite your system
3. use deploy_dens_root.sh for tondev deployment
4. Use test.sh to perform TestSuite4 test cases

# DeBot User interaction

Not ready yet. Stay tuned.

## References

[1]  [https://freeton.org/][Free TON]  Free TON Community

[2]  [https://devex.gov.freeton.org/proposal?proposalAddress=0:6f72de4f9e5e04c949d048716e43cc9b6b33f1236dc7ffd3245c676925ce2a07] #12 Decentralized Name Service (DeNS)

[3]  [https://forum.freeton.org/t/tip-2-decentralized-certificates-decert/7800] TIP-2 Decentralized Certificates (DeCert)

