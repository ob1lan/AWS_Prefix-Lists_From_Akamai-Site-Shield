# AWS Prefix List Updater from Akamai Site Shield Map
This small project is aimed at providing an easy and rather automated way to update AWS Prefix Lists with the latest Akamai Site Shield maps, and confirm those changes have been carried out with Akamai.
## Foreword
### Akamai Site Shield
Site Shield provides an additional layer of defense for your critical websites and web applications. Site Shield effectively removes them from Internet-accessible IP address space. This helps prevent attackers from directly targeting the application origin and forces traffic to go through the Akamai Intelligent Platform, where attacks can be detected and mitigated.
### AWS Managed Prefix Lists
A managed prefix list is a set of one or more CIDR blocks. You can use prefix lists to make it easier to configure and maintain your security groups and route tables. You can create a prefix list from the IP addresses that you frequently use, and reference them as a set in security group rules and routes instead of referencing them individually. For example, you can consolidate security group rules with different CIDR blocks but the same port and protocol into a single rule that uses a prefix list. If you scale your network and need to allow traffic from another CIDR block, you can update the relevant prefix list and all security groups that use the prefix list are updated. You can also use managed prefix lists with other AWS accounts using Resource Access Manager (RAM).

There are two types of prefix lists:

- __Customer-managed prefix lists__ — Sets of IP address ranges that you define and manage. You can share your prefix list with other AWS accounts, enabling those accounts to reference the prefix list in their own resources.
- __AWS-managed prefix lists__ — Sets of IP address ranges for AWS services. You cannot create, modify, share, or delete an AWS-managed prefix list.

In this page, we describe how to update a Customer-managed prefix list.
## Quick Start Guide
0. Get Rancher Desktop (or your favourite containers runtime) installed on your device
1. Clone this repository on your device:
```
git clone git@github.com:ob1lan/Feed_AWS_Prefix-Lists_From_Akamai-Site-Shield.git
```
2. Make sure to update the `.edgrc` and `credentials` files with your keys from Akamai and AWS respectively
3. Build the container from the directory where the `Dockerfile` is located:
```
nerdctl build -t akamaiawscli .
```
4. Run the container and mount the local `/output` directory into the container's `/root/output` directory:
```
# To land a Shell on the container
nerdctl run --rm -it -v $(pwd)/output:/root/output --entrypoint "/bin/bash" akamaiawscli

# To evaluate changes to be applied on a specific AWS Managed Prefix List
nerdctl run --rm -v $(pwd)/output:/root/output akamaiawscli -evaluate_pl <pl-id>

# To perform the changes on a specific AWS Managed Prefix List from Akamai Site Shield maps proposed CIDRs
nerdctl run --rm -v $(pwd)/output:/root/output akamaiawscli -refresh_pl <pl-id> <map-name>
```
Make sure to replace `<pl-id>` and `<map-name>` with the relevant values in the above commands.
Example:
```
nerdctl run --rm -v $(pwd)/output:/root/output akamaiawscli -refresh_pl pl-0b44cf237f8c0892b s15.akamaiedge.net
```
The `evaluate_pl` command will create result files under the `/output` directory:
- a file for CIDRs that will be added to current Prefix List
- a file for CIDRs that will be removed from current Prefix List
- a file for CIDRs that will be left unchanged in the Prefix List
- a file with the CIDRs in the Prefix List before applying any change
- a file with the CIDRs proposed by Akamai for the Site Shield map
## TO DO
- Add a final step to confirm the changes have been processed and the new map addresses are ready to be applied by Akamai.
- Fine-tune the logging and error handling
## Troubleshooting
Currently no troubleshooting advises needed for this page/process.
## Contact
Should you have any remark or suggestion, please reach out to me.
