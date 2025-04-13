#!/usr/bin/env bash

PREAMBLE="$(cat <<'EOF'
# this will execute something
# and generates completions from its new-line separated stdout
_csi_complete() {
    local args func IFS
    func="$1"
    shift
    IFS=$'\t'
    # TODO support batching matches
    while read -r match display; do
        if [ -n "$ZSH_VERSION" ]; then
            local -a matches
            display="${display//$'\t'/    }"
            matches=("$match: $display")
            # TODO use compadd directly
            _describe 'command' matches
        elif [ -n "$BASH_VERSION" ]; then
            local cur="${COMP_WORDS[COMP_CWORD]}"
            compgen -W "$match" -- "$cur"
        fi
    done < <("$func" "$@")
}

_csi_complete_files() {
    if [ -n "$ZSH_VERSION" ]; then
        _files
    elif [ -n "$BASH_VERSION" ]; then
        compgen -f -- "$1"
    fi
}
_csi_complete_cloudshell() { _csi_complete _csi_cloudshell_status; }
_csi_complete_cloudshell_running() { _csi_complete _csi_cloudshell_status RUNNING; }
_csi_complete_cloudshell_suspended() { _csi_complete _csi_cloudshell_status SUSPENDED; }
_csi_complete_ec2() { _csi_complete _csi_ec2; }
_csi_complete_rds() { _csi_complete _csi_rds; }
_csi_complete_eni() { _csi_complete _csi_eni; }
_csi_complete_subnets() { _csi_complete _csi_subnets; }
_csi_complete_sgs() { _csi_complete _csi_sgs; }

_csi_cloudshell_status() {
    csi ls | awk -F'\t' -v status="$1" 'status == "" || $3 == status { print $2, $1, $3, $4, $5 }' OFS='\t'
}
# i need to benchmark
# but i figure python is quicker than aws cli for paginated requests
_csi_ec2() {
    python3 -c "
import boto3
for page in boto3.client('ec2').get_paginator('describe_instances').paginate():
    for reservation in page['Reservations']:
        for instance in reservation['Instances']:
            print(instance['InstanceId'], instance['PublicIpAddress'], sep='\t')
"
}

_csi_rds() {
    python3 -c "
import boto3
for page in boto3.client('rds').get_paginator('describe_db_instances').paginate():
    for instance in page['DBInstances']:
        print(instance['DBInstanceIdentifier'], instance['Engine'], sep='\t')
"
}

_csi_eni() {
    python3 -c "
import boto3
for page in boto3.client('ec2').get_paginator('describe_network_interfaces').paginate():
    for interface in page['NetworkInterfaces']:
        print(interface['PrivateIpAddress'], interface['NetworkInterfaceId'], interface['Status'], sep='\t')
"
}

_csi_subnets() {
    python3 -c "
import boto3
for page in boto3.client('ec2').get_paginator('describe_subnets').paginate():
    for subnet in page['Subnets']:
        name = next((t['Value'] for t in subnet.get('Tags', []) if t['Key'] == 'Name'), '')
        print(subnet['SubnetId'], name, subnet['AvailabilityZone'], subnet['CidrBlock'], subnet['VpcId'], sep='\t')
"
}

_csi_sgs() {
    python3 -c "
import boto3
for page in boto3.client('ec2').get_paginator('describe_security_groups').paginate():
    for group in page['SecurityGroups']:
        print(group['GroupId'], group['GroupName'], group.get('VpcId'), sep='\t')
"
}
EOF
)"

# https://github.com/lincheney/dsv/blob/main/make-completions.sh
set -eu -o pipefail
cd "$(dirname "$0")"
prog=csi
mkdir -p completions/
for shell in bash zsh; do
    output="$(PYTHONPATH= shtab --preamble="$PREAMBLE" --shell="$shell" csi.make_main_parser --error-unimportable --prog "$prog")"
    if ! diff completions/"$prog"."$shell" <(echo "$output"); then
        echo "$output" >completions/"$prog"."$shell"
    fi
done
