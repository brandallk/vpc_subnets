#!/bin/bash

# 1st-Iteration Exercise:
# Create an executable Bash script that will use the AWS CLI to print the CIDR blocks of the VPC and of all subnets
# in it.

# ASSUMPTIONS:
# * You will run this script in a terminal session with active credentials for your personal AWS account.
#   See e.g. https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html for guidance on basic
#     credentials setup for AWS CLI
#   NOTE: It's handy to run the command `aws sts get-caller-identity` to check your active-credentials status in
#     in your terminal session. If you get error...
#     `An error occurred (ExpiredToken) when calling the GetCallerIdentity operation: The security token included in the request is expired`
#     ...that means that your access creds aren't set up correctly.
# * In your AWS account, you have created >= 1 non-default VPC. (Look up the vpc-id for this VP so you can provide
#   it as an argument when you run this script.)
# * In your non-default VPC, you have created >= 1 subnets.
# * To run the script, you may need to make it executable, e.g. `chmod +x first_iteration.sh`

# Example usage: `./first_iteration.sh vpc-0fafd2456afe11d5c`


# vpc-id provided as script argument
VPC_ID=$1

# FUNCTIONS
# -------------------------

print_vpc_cidr () {
  vpc_cidr=$(aws ec2 describe-vpcs --vpc-id "$VPC_ID" | jq -r ".Vpcs[0].CidrBlock")
  echo "$vpc_cidr"
}

print_subnet_cidrs () {
  subnet_cidrs=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" | jq -r ".Subnets[].CidrBlock")
  echo "$subnet_cidrs"
}

# SCRIPT
# -------------------------
print_vpc_cidr
print_subnet_cidrs

# EXAMPLE OUTPUT:
# brk$ ./first_iteration.sh vpc-0fafd2456afe11d5c
# 10.0.0.0/16
# 10.0.1.0/24
# 10.0.0.0/24
