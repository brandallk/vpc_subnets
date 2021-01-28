#! /bin/bash

# Notes
# Some functions are declared at the top of the script.
# The script itself begins about line 390, and uses (some of) the functions declared earlier.
# I've made some simplifying assumptions. No apologies or that: This is intended an illustration and an exploration more
# so than an opportunity to get mired in the ugly details of IP parsing that will be far easier to handle using a language
# such as Python.

# FUNCTIONS
# ----------------------------------------------------------------------------------------------------------------------

get_ip () {
  cidr=$1

  netmask=$(awk -F'/' '{print $1}' <<< $cidr)
  echo $netmask
}

get_netmask () {
  cidr=$1

  netmask=$(awk -F'/' '{print $2}' <<< $cidr)
  echo $netmask
}

convert_ip_to_octets () {
  ip=$1

  octets=$(awk -F'.' '{print $1,$2,$3,$4}' <<< $ip)
  echo $octets
}

get_4th_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $4}' <<< $ip)
  echo $octet
}

get_3rd_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $3}' <<< $ip)
  echo $octet
}

get_2nd_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $2}' <<< $ip)
  echo $octet
}

get_1st_octet () {
  ip=$1

  octet=$(awk -F'.' '{print $1}' <<< $ip)
  echo $octet
}

left_pad () {
  number=$1
  total_length=$2
  pad_char=$3

  padded_number=$(printf "%${total_length}s" $number | tr ' ' $pad_char)
  echo $padded_number
}

right_pad () {
  number=$1
  total_length=$2
  pad_char=$3

  padded_number=$(printf "%-${total_length}s" $number | tr ' ' $pad_char)
  echo $padded_number
}

convert_to_binary () {
  decimal_number=$1

  binary_number=$(bc <<< "obase=2;ibase=10;${decimal_number}")
  echo $binary_number
}

convert_to_decimal () {
  binary_number=$1

  decimal_number=$(bc <<< "obase=10;ibase=2;${binary_number}")
  echo $decimal_number
}

delimit_octets_in_binary_ip () {
  undelimited_ip=$1

  octet1=$(cut -c1-8 <<< $undelimited_ip)
  octet2=$(cut -c9-16 <<< $undelimited_ip)
  octet3=$(cut -c17-24 <<< $undelimited_ip)
  octet4=$(cut -c24-32 <<< $undelimited_ip)

  ip="${octet1}.${octet2}.${octet3}.${octet4}"

  echo $ip
}

remove_delimiters_from_binary_ip () {
  delimited_ip=$1

  octets=$(convert_ip_to_octets $delimited_ip)
  undelimited_ip=""

  for octet in $octets; do
    undelimited_ip="${undelimited_ip}${octet}";
  done;

  echo $undelimited_ip
}

convert_decimal_ip_to_binary_ip () {
  ip=$1

  octets=$(awk -F'.' '{print $1,$2,$3,$4}' <<< $ip)
  binary_ip=""

  for octet in $octets; do
    octet_bits=$(convert_to_binary $octet);
    padded_octet_bits=$(left_pad $octet_bits 8 0)
    binary_ip="${binary_ip}.${padded_octet_bits}";
  done;

  ip=$(cut -c2-36 <<< $binary_ip)

  echo $ip
}

convert_binary_ip_to_decimal_ip (){
  ip=$1

  octets=$(awk -F'.' '{print $1,$2,$3,$4}' <<< $ip)
  decimal_ip=""

  for octet in $octets; do
    octet_number=$(convert_to_decimal $octet);
    decimal_ip="${decimal_ip}.${octet_number}";
  done;

  ip=$(cut -c2-36 <<< $decimal_ip)

  echo $ip
}

get_lower_bound () {
  binary_ip=$1
  mask=$2

  undelimited_ip=$(remove_delimiters_from_binary_ip $binary_ip)

  lower_bound=$(cut -c1-$mask <<< $undelimited_ip)
  padded_lower_bound=$(right_pad $lower_bound 31 0)

  delimited_ip=$(delimit_octets_in_binary_ip $padded_lower_bound)

  echo $delimited_ip
}

get_upper_bound () {
  binary_ip=$1
  mask=$2

  undelimited_ip=$(remove_delimiters_from_binary_ip $binary_ip)

  lower_bound=$(cut -c1-$mask <<< $undelimited_ip)
  upper_bound=$(right_pad $lower_bound 31 1)

  delimited_ip=$(delimit_octets_in_binary_ip $upper_bound)

  echo $delimited_ip
}

get_upper_bound_plus_1 () {
  binary_ip=$1
  mask=$2

  undelimited_ip=$(remove_delimiters_from_binary_ip $binary_ip)

  mask_shifted_left_1=$mask
  if [[ ! "${mask}" -eq 0 ]]; then
    mask_shifted_left_1=$(( $mask - 1 ))
  fi;

  lower_bound=$(cut -c1-$mask <<< $undelimited_ip)
  upper_bound="${lower_bound}1"
  padded_upper_bound=$(right_pad $upper_bound 32 0)

  delimited_ip=$(delimit_octets_in_binary_ip $upper_bound)

  echo $delimited_ip
}

is_in () {
	lower_bound=$1
	upper_bound=$2
	target=$3

	if [[ $lower_bound -le $target && $target -le $upper_bound ]]; then
		echo "true";
	else
		echo "false";
	fi;
}

cidr_is_in_cidr () {
  contained_cidr=$1
  container_cidr=$2

  contained_cidr_ip=$(get_ip $contained_cidr)
  contained_cidr_ip_binary=$(convert_decimal_ip_to_binary_ip $contained_cidr_ip)
  contained_cidr_mask=$(get_netmask $contained_cidr)
  contained_cidr_lower_bound=$(get_lower_bound $contained_cidr_ip_binary $contained_cidr_mask)
  contained_cidr_lower_bound=$(remove_delimiters_from_binary_ip $contained_cidr_lower_bound)
  contained_cidr_upper_bound=$(get_upper_bound $contained_cidr_ip_binary $contained_cidr_mask)
  contained_cidr_upper_bound=$(remove_delimiters_from_binary_ip $contained_cidr_upper_bound)

  container_cidr_ip=$(get_ip $container_cidr)
  container_cidr_ip_binary=$(convert_decimal_ip_to_binary_ip $container_cidr_ip)
  container_cidr_mask=$(get_netmask $container_cidr)
  container_cidr_lower_bound=$(get_lower_bound $container_cidr_ip_binary $container_cidr_mask)
  container_cidr_lower_bound=$(remove_delimiters_from_binary_ip $container_cidr_lower_bound)
  container_cidr_upper_bound=$(get_upper_bound $container_cidr_ip_binary $container_cidr_mask)
  container_cidr_upper_bound=$(remove_delimiters_from_binary_ip $container_cidr_upper_bound)

  if [[ "${contained_cidr_lower_bound}" -ge "${container_cidr_lower_bound}" && "${contained_cidr_upper_bound}" -le "${container_cidr_upper_bound}" ]]; then
    echo "true";
  else
    echo "false";
  fi;
}

host_ips_are_in_4th_octet () {
  netmask=$1

  answer=$(is_in 24 32 $netmask)
  echo $answer
}

host_ips_are_in_3rd_octet () {
  netmask=$1

  answer=$(is_in 16 23 $netmask)
  echo $answer
}

host_ips_are_in_2nd_octet () {
  netmask=$1

  answer=$(is_in 8 15 $netmask)
  echo $answer
}

host_ips_are_in_1st_octet () {
  netmask=$1

  answer=$(is_in 0 7 $netmask)
  echo $answer
}

subtract_cidr_from_cidr_get_upper_1st_ip () {
  subtrahend_cidr_decimal=$1
  minuend_cidr_decimal=$2

  subtrahend_ip_decimal=$(get_ip $subtrahend_cidr_decimal)
  subtrahend_mask=$(get_netmask $subtrahend_cidr_decimal)
  subtrahend_octet1=$(get_1st_octet $subtrahend_ip_decimal)
  subtrahend_octet2=$(get_2nd_octet $subtrahend_ip_decimal)
  subtrahend_octet3=$(get_3rd_octet $subtrahend_ip_decimal)
  subtrahend_octet4=$(get_4th_octet $subtrahend_ip_decimal)

  subtrahend_ips_are_in_1st_octet=$(host_ips_are_in_1st_octet $subtrahend_mask)
  subtrahend_ips_are_in_2nd_octet=$(host_ips_are_in_2nd_octet $subtrahend_mask)
  subtrahend_ips_are_in_3rd_octet=$(host_ips_are_in_3rd_octet $subtrahend_mask)
  subtrahend_ips_are_in_4th_octet=$(host_ips_are_in_4th_octet $subtrahend_mask)

  result_upper_1st_ip_octet1=$subtrahend_octet1
  result_upper_1st_ip_octet2=$subtrahend_octet2
  result_upper_1st_ip_octet3=$subtrahend_octet3
  result_upper_1st_ip_octet4=$subtrahend_octet4

  if [ "${subtrahend_ips_are_in_1st_octet}" = "true" ]; then
    result_upper_1st_ip_octet1=$(bc <<< "subtrahend_octet1 + 2^( 8 - ${subtrahend_mask} )")
  fi;

  if [ "${subtrahend_ips_are_in_2nd_octet}" = "true" ]; then
    result_upper_1st_ip_octet2=$(bc <<< "subtrahend_octet2 + 2^( 16 - ${subtrahend_mask} )")
  fi;

  if [ "${subtrahend_ips_are_in_3rd_octet}" = "true" ]; then
    result_upper_1st_ip_octet3=$(bc <<< "subtrahend_octet3 + 2^( 24 - ${subtrahend_mask} )")
  fi;

  if [ "${subtrahend_ips_are_in_4th_octet}" = "true" ]; then
    result_upper_1st_ip_octet4=$(bc <<< "subtrahend_octet4 + 2^( 32 - ${subtrahend_mask} )")
  fi;

  if [ "${result_upper_1st_ip_octet4}" = "256" ]; then
    result_upper_1st_ip_octet4="0"
    result_upper_1st_ip_octet3=$(( result_upper_1st_ip_octet3 + 1 ))
  fi;

  if [ "${result_upper_1st_ip_octet3}" = "256" ]; then
    result_upper_1st_ip_octet3="0"
    result_upper_1st_ip_octet2=$(( result_upper_1st_ip_octet2 + 1 ))
  fi;

  if [ "${result_upper_1st_ip_octet2}" = "256" ]; then
    result_upper_1st_ip_octet2="0"
    result_upper_1st_ip_octet1=$(( result_upper_1st_ip_octet1 + 1 ))
  fi;

  if [ "${result_upper_1st_ip_octet1}" = "256" ]; then
    result_upper_1st_ip_octet1="0"
  fi;

  result_upper_1st_ip="${result_upper_1st_ip_octet1}.${result_upper_1st_ip_octet2}.${result_upper_1st_ip_octet3}.${result_upper_1st_ip_octet4}"

  echo $result_upper_1st_ip
}

subtract_cidr_from_cidr_get_upper_last_ip () {
  subtrahend_cidr_decimal=$1
  minuend_cidr_decimal=$2

  minuend_ip_binary=$(convert_decimal_ip_to_binary_ip $minuend_cidr_decimal)
  minuend_mask=$(get_netmask $minuend_cidr_decimal)

  last_ip=$(get_upper_bound $minuend_ip_binary $minuend_mask)
  last_ip_decimal=$(convert_binary_ip_to_decimal_ip $last_ip)

  echo $last_ip_decimal
}

subtract_cidr_from_cidr_get_upper_block () {
  subtrahend_cidr_decimal=$1
  minuend_cidr_decimal=$2

  first_ip_in_block=$(subtract_cidr_from_cidr_get_upper_1st_ip $subtrahend_cidr_decimal $minuend_cidr_decimal)
  last_ip_in_block=$(subtract_cidr_from_cidr_get_upper_last_ip $subtrahend_cidr_decimal $minuend_cidr_decimal)

  printf "IP range:\n1st IP: ${first_ip_in_block}\nLast IP: ${last_ip_in_block}\n"
}

ip_count_in_range () {
  range_netmask=$1

  ip_count=$( bc <<< "2^(32 - ${range_netmask})" )

  echo $ip_count
}

subnets_of_size_in_ip_range () {
  subnet_netmask=$1
  range_netmask=$2

  range_ips=$(ip_count_in_range $range_netmask)
  subnet_ips=$(ip_count_in_range $subnet_netmask)

  subnet_count=$(( range_ips / subnet_ips ))

  echo $subnet_count
}

highest_subnet () {
  subnets=("$@")
  highest_undelimited=""
  highest_subnet=""

  for subnet in "${subnets[@]}"; do
    subnet_ip=$(get_ip $subnet)
    subnet_ip_binary=$(convert_decimal_ip_to_binary_ip $subnet_ip)
    undelimited_subnet_ip=$(remove_delimiters_from_binary_ip $subnet_ip_binary)
    if [[ "${undelimited_subnet_ip}" -ge "${highest_undelimited}" ]]; then
      highest_undelimited=$undelimited_subnet_ip
      highest_subnet=$subnet
    fi;
  done;

  echo $highest_subnet
}


# SCRIPT
# ----------------------------------------------------------------------------------------------------------------------

# Note: This is a handy way to check if you're being identified as expected by the AWS CLI
# If you run this command and get the error...
#    `An error occurred (ExpiredToken) when calling the GetCallerIdentity operation: The security token included in the request is expired`
# ...that means that your access creds aren't set up correctly
aws sts get-caller-identity

VPC_ID=$1
SUBNET_SIZE=$2

vpc_cidr=$(aws ec2 describe-vpcs --vpc-id $VPC_ID | jq -r ".Vpcs[0].CidrBlock")
echo "vpc cidr: ${vpc_cidr}"

subnet_cidrs=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID | jq -r ".Subnets[].CidrBlock")
echo "subnet cidrs: ${subnet_cidrs}"

# assumption: our VPC is filled up from the bottom
highest_subnet_in_vpc=$(highest_subnet $subnet_cidrs)
echo $highest_subnet_in_vpc

first_available_ip=$(subtract_cidr_from_cidr_get_upper_1st_ip $highest_subnet_in_vpc $vpc_cidr)
echo "first available IP in VPC: ${first_available_ip}"

last_available_ip=$(subtract_cidr_from_cidr_get_upper_last_ip $highest_subnet_in_vpc $vpc_cidr)
echo "last available IP in VPC: ${last_available_ip}"

vpc_netmask=$(get_netmask $vpc_cidr)

available_subnets_of_given_size=$(subnets_of_size_in_ip_range $SUBNET_SIZE $vpc_netmask)
echo "available subnets: ${available_subnets_of_given_size}"
