#!/bin/bash

# 3rd-Iteration Exercise:
# The script takes a parameter representing a network-mask size (e.g. “24”), and uses it to calculate and print the
# number of available subnets of that size in the VPC.

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
# * To run the script, you may need to make it executable, e.g. `chmod +x third_iteration.sh`

# Example usage: `./third_iteration.sh vpc-0fafd2456afe11d5c 24`


# vpc-id provided as 1st script argument
VPC_ID=$1

# subnet size (netmask) provided as 2nd script argument
SUBNET_SIZE=$2

# FUNCTIONS
# -------------------------

get_vpc_cidr () {
  vpc_cidr=$(aws ec2 describe-vpcs --vpc-id "$VPC_ID" | jq -r ".Vpcs[0].CidrBlock")
  echo "$vpc_cidr"
}

# get the netmask portion of a CIDR
get_netmask () {
  cidr=$1

  netmask=$(awk -F'/' '{print $2}' <<< "$cidr")
  echo "$netmask"
}

ip_count_in_range () {
  range_netmask=$1

  ip_count=$( bc <<< "2^(32 - ${range_netmask})" )

  echo "$ip_count"
}

subnets_of_size_in_ip_range () {
  subnet_netmask=$1
  range_netmask=$2

  range_ips=$(ip_count_in_range "$range_netmask")
  subnet_ips=$(ip_count_in_range "$subnet_netmask")

  subnet_count=$(( range_ips / subnet_ips ))

  echo "$subnet_count"
}

# SCRIPT
# -------------------------
vpc_cidr=$(get_vpc_cidr)
vpc_netmask=$(get_netmask "$vpc_cidr")

available_subnets_of_given_size=$(subnets_of_size_in_ip_range "$SUBNET_SIZE" "$vpc_netmask")
echo "available subnets: ${available_subnets_of_given_size}"

# EXAMPLE OUTPUT:
# brk$ ./third_iteration.sh vpc-0fafd2456afe11d5c 24
# available subnets: 256
