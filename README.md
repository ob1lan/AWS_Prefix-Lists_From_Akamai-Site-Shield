# Akamai Site Shield Updater
This small project is aimed at providing an easy and rather automated way to update the AWS Managed Prefix Lists with the latest Akamai Site Shield maps, and confirm those changes have been carried out with Akamai.
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
0. Get [Rancher Desktop](https://rancherdesktop.io/) (or your favourite containers runtime) installed on your device
1. Clone this repository on your device:
```bash
git clone https://github.com/ob1lan/AWS_Prefix-Lists_From_Akamai-Site-Shield.git
```
2. Make sure to update the [.edgerc](https://techdocs.akamai.com/developer/docs/set-up-authentication-credentials) and [credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) files with your keys from Akamai and AWS respectively
3. Build the container from the directory where the `Dockerfile` is located:
```
nerdctl build -t akamaiawscli .
```
4. Run the container and mount the local `/output` directory into the container's `/root/output` directory:
```
# To land a Shell on the container
nerdctl run --rm -it -v $(pwd)/output:/root/output --entrypoint "/bin/bash" akamaiawscli

# To evaluate changes to be applied on a specific AWS Managed Prefix List
nerdctl run --rm -v $(pwd)/output:/root/output akamaiawscli evaluate_pl <pl-id> <region>

# To perform the changes on a specific AWS Managed Prefix List from Akamai Site Shield maps proposed CIDRs (interractive mode)
nerdctl run --rm -it -v $(pwd)/output:/root/output akamaiawscli refresh_pl <pl-id> <map-name> <region>
```
Make sure to replace `<pl-id>`, `<map-name>` and `<region>` with the relevant values in the above commands.
Example:
```
nerdctl run --rm -it -v $(pwd)/output:/root/output akamaiawscli refresh_pl pl-0a49cf427f8c0954e s155.akamaiedge.net eu-central-1
```
The `evaluate_pl` command will create result files under the `/output` directory:
- a file for CIDRs that will be added to current Prefix List
- a file for CIDRs that will be removed from current Prefix List
- a file for CIDRs that will be left unchanged in the Prefix List
- a file with the CIDRs in the Prefix List before applying any change
- a file with the CIDRs proposed by Akamai for the Site Shield map
## Troubleshooting
### DNS resolution
If the commands fail, make sure your container is able to perform DNS resolution, and if needed update your container's `resolv.conf` file:
```
rdctl shell
vi /etc/resolv.conf
```
In that file, make sure to replace the IP with 8.8.8.8 or any other working DNS server. The `resolv.conf` file should look like this:
```
nameserver 8.8.8.8
```
## Contact
Should you have any remark or suggestion, please contact me directly.
