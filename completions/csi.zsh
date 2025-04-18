#compdef csi

# AUTOMATICALLY GENERATED by `shtab`


_shtab_csi_commands() {
  local _commands=(
    "create:Create a new CloudShell environment"
    "delete:Delete a CloudShell environment"
    "download:Download a file from a CloudShell environment"
    "execute:Executes a command on a CloudShell environment"
    "genie:Magically creates and connects to a CloudShell environment with the correct network access to reach the resource you specify"
    "list:List available CloudShell environments"
    "ls:List available CloudShell environments"
    "ssm:SSM to a CloudShell environment"
    "start:Start a CloudShell environment"
    "stop:Stop a CloudShell environment"
    "upload:Upload a file to a CloudShell environment"
  )
  _describe 'csi commands' _commands
}

_shtab_csi_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  {-l,--log}"[Logging level (default\: info)]:log:(debug info warning error critical)"
)

_shtab_csi_create_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  "--name[Name for environment (required for VPC environment)]:name:"
  "--subnets[Subnet IDs (required for VPC environment)]:subnets:_csi_complete_subnets"
  "--security-groups[Security Group IDs (default\: the default security group)]:security_groups:_csi_complete_sgs"
)

_shtab_csi_delete_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:_csi_complete_cloudshell"
)

_shtab_csi_download_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:_csi_complete_cloudshell"
  ":File on CloudShell to download:"
  ":Destination path:_csi_complete_files"
)

_shtab_csi_execute_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  {--cmd,-c}"[]:cmd:"
  ":id:_csi_complete_cloudshell"
)

_shtab_csi_genie_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  "--ip[IP address of ENI]:ip:_csi_complete_eni"
  "--host[Publicly resolvable hostname]:host:"
  "--ec2[EC2 instance ID]:ec2:_csi_complete_ec2"
  "--rds[RDS instance ID]:rds:_csi_complete_rds"
  "--port[Port to connect on (optional for --rds)]:port:"
  "--protocol[IP protocol to connect on (default\: tcp)]:protocol:(tcp udp any)"
  "--tmp[Clean up CloudShell environment on exit (if new)]"
  "--output-id[Output the ID to stdout and do not connect]"
)

_shtab_csi_list_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  "--security-groups[Display security groups in output]"
)

_shtab_csi_ls_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  "--security-groups[Display security groups in output]"
)

_shtab_csi_ssm_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:_csi_complete_cloudshell"
)

_shtab_csi_start_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:_csi_complete_cloudshell_suspended"
)

_shtab_csi_stop_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:_csi_complete_cloudshell_running"
)

_shtab_csi_upload_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:_csi_complete_cloudshell"
  ":File from machine to upload:_csi_complete_files"
  ":Destination path:"
)


_shtab_csi() {
  local context state line curcontext="$curcontext" one_or_more='(-)*' remainder='(*)'

  if ((${_shtab_csi_options[(I)${(q)one_or_more}*]} + ${_shtab_csi_options[(I)${(q)remainder}*]} == 0)); then  # noqa: E501
    _shtab_csi_options+=(': :_shtab_csi_commands' '*::: :->csi')
  fi
  _arguments -C -s $_shtab_csi_options

  case $state in
    csi)
      words=($line[1] "${words[@]}")
      (( CURRENT += 1 ))
      curcontext="${curcontext%:*:*}:_shtab_csi-$line[1]:"
      case $line[1] in
        create) _arguments -C -s $_shtab_csi_create_options ;;
        delete) _arguments -C -s $_shtab_csi_delete_options ;;
        download) _arguments -C -s $_shtab_csi_download_options ;;
        execute) _arguments -C -s $_shtab_csi_execute_options ;;
        genie) _arguments -C -s $_shtab_csi_genie_options ;;
        list) _arguments -C -s $_shtab_csi_list_options ;;
        ls) _arguments -C -s $_shtab_csi_ls_options ;;
        ssm) _arguments -C -s $_shtab_csi_ssm_options ;;
        start) _arguments -C -s $_shtab_csi_start_options ;;
        stop) _arguments -C -s $_shtab_csi_stop_options ;;
        upload) _arguments -C -s $_shtab_csi_upload_options ;;
      esac
  esac
}

# Custom Preamble
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
            name = next((t['Value'] for t in instance.get('Tags', []) if t['Key'] == 'Name'), '')
            print(instance['InstanceId'], name, instance['PlatformDetails'], instance['State']['Name'], instance['InstanceType'], instance['LaunchTime'], instance['Placement']['AvailabilityZone'], instance['PrivateIpAddress'], sep='\t')
"
}

_csi_rds() {
    python3 -c "
import boto3
for page in boto3.client('rds').get_paginator('describe_db_instances').paginate():
    for instance in page['DBInstances']:
        print(instance['DBInstanceIdentifier'], instance['Engine'], instance['DBName'], sep='\t')
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

# End Custom Preamble


typeset -A opt_args

if [[ $zsh_eval_context[-1] == eval ]]; then
  # eval/source/. command, register function for later
  compdef _shtab_csi -N csi
else
  # autoload from fpath, call function directly
  _shtab_csi "$@"
fi
