#!/bin/bash

# 2nd-Iteration Exercise:
# Rather than print the CIDR blocks, use them to calculate and print the IP range for the largest contiguous block
# of free IPs left in the VPC.

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
# * To run the script, you may need to make it executable, e.g. `chmod +x second_iteration.sh`

# SIMPLIFYING ASSUMPTION: The VPC is always "filled" with subnets covering a contiguous IP block starting from the
#   bottom end, leaving one large contiguous block of available IP addresses for new subnets at the top end of the
#   VPC CIDR. This allows focusing on some fundamentals of bash scripting and networking without getting too mired
#   in ugly albeit real-world-type complexities.

# Example usage: `./second_iteration.sh vpc-0fafd2456afe11d5c`


# vpc-id provided as script argument
VPC_ID=$1

# FUNCTIONS
# -------------------------

get_vpc_cidr () {
  vpc_cidr=$(aws ec2 describe-vpcs --vpc-id "$VPC_ID" | jq -r ".Vpcs[0].CidrBlock")
  echo "$vpc_cidr"
}

get_subnet_cidrs () {
  subnet_cidrs=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" | jq -r ".Subnets[].CidrBlock")
  echo "$subnet_cidrs"
}

# get the IP portion of a CIDR
get_ip () {
  cidr=$1

  ip=$(awk -F'/' '{print $1}' <<< "$cidr")
  echo "$ip"
}

# get the netmask portion of a CIDR
get_netmask () {
  cidr=$1

  netmask=$(awk -F'/' '{print $2}' <<< "$cidr")
  echo "$netmask"
}

convert_to_binary () {
  decimal_number=$1

  binary_number=$(bc <<< "obase=2;ibase=10;${decimal_number}")
  echo "$binary_number"
}

convert_to_decimal () {
  binary_number=$1

  decimal_number=$(bc <<< "obase=10;ibase=2;${binary_number}")
  echo "$decimal_number"
}

# pad the given number with the given character on the left side to the total given string length
left_pad () {
  number=$1
  total_length=$2
  pad_char=$3

  padded_number=$(printf "%${total_length}s" "$number" | tr ' ' "$pad_char")
  echo "$padded_number"
}

# pad the given number with the given character on the right side to the total given string length
right_pad () {
  number=$1
  total_length=$2
  pad_char=$3

  padded_number=$(printf "%-${total_length}s" "$number" | tr ' ' "$pad_char")
  echo "$padded_number"
}

# e.g. convert 10.0.1.0 to 00001010.00000000.00000001.0000000
convert_decimal_ip_to_binary_ip () {
  ip=$1

  octets=$(awk -F'.' '{print $1,$2,$3,$4}' <<< "$ip")
  binary_ip=""

  for octet in $octets; do
    octet_bits=$(convert_to_binary "$octet");
    padded_octet_bits=$(left_pad "$octet_bits" 8 0)
    binary_ip="${binary_ip}.${padded_octet_bits}";
  done;

  binary_ip=$(cut -c2-36 <<< "$binary_ip")

  echo "$binary_ip"
}

# e.g. convert 00001010.00000000.00000001.0000000 to 10.0.1.0
convert_binary_ip_to_decimal_ip (){
  ip=$1

  octets=$(awk -F'.' '{print $1,$2,$3,$4}' <<< "$ip")
  decimal_ip=""

  for octet in $octets; do
    octet_number=$(convert_to_decimal "$octet");
    decimal_ip="${decimal_ip}.${octet_number}";
  done;

  ip=$(cut -c2-36 <<< "$decimal_ip")

  echo "$ip"
}

get_ip_octets () {
  ip=$1

  octets=$(awk -F'.' '{print $1,$2,$3,$4}' <<< "$ip")
  echo "$octets"
}

get_1st_ip_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $1}' <<< "$ip")
  echo "$octet"
}

get_2nd_ip_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $2}' <<< "$ip")
  echo "$octet"
}

get_3rd_ip_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $3}' <<< "$ip")
  echo "$octet"
}

get_4th_ip_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $4}' <<< "$ip")
  echo "$octet"
}

# determine if the given_number is within the range represented by the given max/min values
is_in () {
  range_min=$1
	range_max=$2
	given_number=$3

	if [[ $range_min -le $given_number && $given_number -le $range_max ]]; then
		echo "true";
	else
		echo "false";
	fi;
}

host_ips_are_in_1st_octet () {
  netmask=$1

  answer=$(is_in 0 7 "$netmask")
  echo "$answer"
}

host_ips_are_in_2nd_octet () {
  netmask=$1

  answer=$(is_in 8 15 "$netmask")
  echo "$answer"
}

host_ips_are_in_3rd_octet () {
  netmask=$1

  answer=$(is_in 16 23 "$netmask")
  echo "$answer"
}

host_ips_are_in_4th_octet () {
  netmask=$1

  answer=$(is_in 24 32 "$netmask")
  echo "$answer"
}

# remove the "." characters between octets of a binary IP address
remove_delimiters_from_binary_ip () {
  delimited_ip=$1

  octets=$(get_ip_octets "$delimited_ip")
  undelimited_ip=""

  for octet in $octets; do
    undelimited_ip="${undelimited_ip}${octet}";
  done;

  echo "$undelimited_ip"
}

# restore the "." characters between octets of a binary IP address
delimit_octets_in_binary_ip () {
  undelimited_ip=$1

  octet1=$(cut -c1-8 <<< "$undelimited_ip")
  octet2=$(cut -c9-16 <<< "$undelimited_ip")
  octet3=$(cut -c17-24 <<< "$undelimited_ip")
  octet4=$(cut -c24-32 <<< "$undelimited_ip")

  ip="${octet1}.${octet2}.${octet3}.${octet4}"

  echo "$ip"
}

# select the subnet from a lis of subnets that has the highest (last) IP block
get_last_subnet () {
  subnets=("$@")
  last_undelimited=""
  last_subnet=""

  for subnet in "${subnets[@]}"; do
    subnet_ip=$(get_ip "$subnet")
    subnet_ip_binary=$(convert_decimal_ip_to_binary_ip "$subnet_ip")
    undelimited_subnet_ip=$(remove_delimiters_from_binary_ip "$subnet_ip_binary")
    if [[ "${undelimited_subnet_ip}" -ge "${last_undelimited}" ]]; then
      last_undelimited="$undelimited_subnet_ip"
      last_subnet="$subnet"
    fi;
  done;

  echo "$last_subnet"
}

# subtract one cidr (the "subtrahend") from another (the "minuend") and return the 1st (lowest) IP in the
# uppermost of the resulting IP ranges
get_first_available_ip () {
  subtrahend_cidr_decimal=$1
  minuend_cidr_decimal=$2

  subtrahend_ip_decimal=$(get_ip "$subtrahend_cidr_decimal")
  subtrahend_mask=$(get_netmask "$subtrahend_cidr_decimal")
  subtrahend_octet1=$(get_1st_ip_octet "$subtrahend_ip_decimal")
  subtrahend_octet2=$(get_2nd_ip_octet "$subtrahend_ip_decimal")
  subtrahend_octet3=$(get_3rd_ip_octet "$subtrahend_ip_decimal")
  subtrahend_octet4=$(get_4th_ip_octet "$subtrahend_ip_decimal")

  subtrahend_ips_are_in_1st_octet=$(host_ips_are_in_1st_octet "$subtrahend_mask")
  subtrahend_ips_are_in_2nd_octet=$(host_ips_are_in_2nd_octet "$subtrahend_mask")
  subtrahend_ips_are_in_3rd_octet=$(host_ips_are_in_3rd_octet "$subtrahend_mask")
  subtrahend_ips_are_in_4th_octet=$(host_ips_are_in_4th_octet "$subtrahend_mask")

  first_ip_octet1=$subtrahend_octet1
  first_ip_octet2=$subtrahend_octet2
  first_ip_octet3=$subtrahend_octet3
  first_ip_octet4=$subtrahend_octet4

  if [ "${subtrahend_ips_are_in_1st_octet}" = "true" ]; then
    first_ip_octet1=$(bc <<< "subtrahend_octet1 + 2^( 8 - ${subtrahend_mask} )")
  fi;

  if [ "${subtrahend_ips_are_in_2nd_octet}" = "true" ]; then
    first_ip_octet2=$(bc <<< "subtrahend_octet2 + 2^( 16 - ${subtrahend_mask} )")
  fi;

  if [ "${subtrahend_ips_are_in_3rd_octet}" = "true" ]; then
    first_ip_octet3=$(bc <<< "subtrahend_octet3 + 2^( 24 - ${subtrahend_mask} )")
  fi;

  if [ "${subtrahend_ips_are_in_4th_octet}" = "true" ]; then
    first_ip_octet4=$(bc <<< "subtrahend_octet4 + 2^( 32 - ${subtrahend_mask} )")
  fi;

  if [ "${first_ip_octet4}" = "256" ]; then
    first_ip_octet4="0"
    first_ip_octet3=$(( first_ip_octet3 + 1 ))
  fi;

  if [ "${first_ip_octet3}" = "256" ]; then
    first_ip_octet3="0"
    first_ip_octet2=$(( first_ip_octet2 + 1 ))
  fi;

  if [ "${first_ip_octet2}" = "256" ]; then
    first_ip_octet2="0"
    first_ip_octet1=$(( first_ip_octet1 + 1 ))
  fi;

  if [ "${first_ip_octet1}" = "256" ]; then
    first_ip_octet1="0"
  fi;

  first_ip="${first_ip_octet1}.${first_ip_octet2}.${first_ip_octet3}.${first_ip_octet4}"

  echo $first_ip
}

get_last_ip_in_cidr () {
  binary_ip=$1
  mask=$2

  undelimited_ip=$(remove_delimiters_from_binary_ip "$binary_ip")

  lower_bound=$(cut -c1-$mask <<< "$undelimited_ip")
  upper_bound=$(right_pad "$lower_bound" 31 1)

  delimited_ip=$(delimit_octets_in_binary_ip "$upper_bound")

  echo "$delimited_ip"
}

# subtract one cidr (the "subtrahend") from another (the "minuend") and return the last (highest) IP in the
# uppermost of the resulting IP ranges
get_last_available_ip () {
  subtrahend_cidr_decimal=$1
  minuend_cidr_decimal=$2

  minuend_ip_binary=$(convert_decimal_ip_to_binary_ip "$minuend_cidr_decimal")
  minuend_netmask=$(get_netmask "$minuend_cidr_decimal")

  last_ip=$(get_last_ip_in_cidr "$minuend_ip_binary" "$minuend_netmask")
  last_ip_decimal=$(convert_binary_ip_to_decimal_ip "$last_ip")

  echo "$last_ip_decimal"
}

# SCRIPT
# -------------------------

vpc_cidr=$(get_vpc_cidr)
subnet_cidrs=$(get_subnet_cidrs)

last_used_subnet_in_vpc=$(get_last_subnet $subnet_cidrs)

first_available_ip_in_vpc=$(get_first_available_ip "$last_used_subnet_in_vpc" "$vpc_cidr")

last_available_ip=$(get_last_available_ip "$last_used_subnet_in_vpc" "$vpc_cidr")

echo "available IP range in VPC: ${first_available_ip_in_vpc} to ${last_available_ip}"

# EXAMPLE OUTPUT:
# brk$ ./second_iteration.sh vpc-0fafd2456afe11d5c
# available IP range in VPC: 10.0.2.0 to 10.0.255.255