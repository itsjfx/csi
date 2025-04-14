# AUTOMATICALLY GENERATED by `shtab`

_shtab_csi_subparsers=('ls' 'list' 'create' 'start' 'delete' 'stop' 'ssm' 'execute' 'upload' 'download' 'genie')

_shtab_csi_option_strings=('-h' '--help' '-l' '--log')
_shtab_csi_ls_option_strings=('-h' '--help' '--security-groups')
_shtab_csi_list_option_strings=('-h' '--help' '--security-groups')
_shtab_csi_create_option_strings=('-h' '--help' '--name' '--subnets' '--security-groups')
_shtab_csi_start_option_strings=('-h' '--help')
_shtab_csi_delete_option_strings=('-h' '--help')
_shtab_csi_stop_option_strings=('-h' '--help')
_shtab_csi_ssm_option_strings=('-h' '--help')
_shtab_csi_execute_option_strings=('-h' '--help' '--cmd' '-c')
_shtab_csi_upload_option_strings=('-h' '--help')
_shtab_csi_download_option_strings=('-h' '--help')
_shtab_csi_genie_option_strings=('-h' '--help' '--ip' '--host' '--ec2' '--rds' '--port' '--protocol' '--tmp' '--output-id')

_shtab_csi_create___subnets_COMPGEN=_csi_complete_subnets
_shtab_csi_create___security_groups_COMPGEN=_csi_complete_sgs
_shtab_csi_start_pos_0_COMPGEN=_csi_complete_cloudshell_suspended
_shtab_csi_delete_pos_0_COMPGEN=_csi_complete_cloudshell
_shtab_csi_stop_pos_0_COMPGEN=_csi_complete_cloudshell_running
_shtab_csi_ssm_pos_0_COMPGEN=_csi_complete_cloudshell
_shtab_csi_execute_pos_0_COMPGEN=_csi_complete_cloudshell
_shtab_csi_upload_pos_0_COMPGEN=_csi_complete_cloudshell
_shtab_csi_upload_pos_1_COMPGEN=_csi_complete_files
_shtab_csi_download_pos_0_COMPGEN=_csi_complete_cloudshell
_shtab_csi_download_pos_2_COMPGEN=_csi_complete_files
_shtab_csi_genie___ip_COMPGEN=_csi_complete_eni
_shtab_csi_genie___ec2_COMPGEN=_csi_complete_ec2
_shtab_csi_genie___rds_COMPGEN=_csi_complete_rds

_shtab_csi_pos_0_choices=('ls' 'list' 'create' 'start' 'delete' 'stop' 'ssm' 'execute' 'upload' 'download' 'genie')
_shtab_csi__l_choices=('debug' 'info' 'warning' 'error' 'critical')
_shtab_csi___log_choices=('debug' 'info' 'warning' 'error' 'critical')
_shtab_csi_genie___protocol_choices=('tcp' 'udp' 'any')

_shtab_csi_pos_0_nargs=A...
_shtab_csi__h_nargs=0
_shtab_csi___help_nargs=0
_shtab_csi_ls__h_nargs=0
_shtab_csi_ls___help_nargs=0
_shtab_csi_ls___security_groups_nargs=0
_shtab_csi_list__h_nargs=0
_shtab_csi_list___help_nargs=0
_shtab_csi_list___security_groups_nargs=0
_shtab_csi_create__h_nargs=0
_shtab_csi_create___help_nargs=0
_shtab_csi_create___subnets_nargs=*
_shtab_csi_create___security_groups_nargs=*
_shtab_csi_start__h_nargs=0
_shtab_csi_start___help_nargs=0
_shtab_csi_delete__h_nargs=0
_shtab_csi_delete___help_nargs=0
_shtab_csi_stop__h_nargs=0
_shtab_csi_stop___help_nargs=0
_shtab_csi_ssm__h_nargs=0
_shtab_csi_ssm___help_nargs=0
_shtab_csi_execute__h_nargs=0
_shtab_csi_execute___help_nargs=0
_shtab_csi_upload__h_nargs=0
_shtab_csi_upload___help_nargs=0
_shtab_csi_download__h_nargs=0
_shtab_csi_download___help_nargs=0
_shtab_csi_genie__h_nargs=0
_shtab_csi_genie___help_nargs=0
_shtab_csi_genie___tmp_nargs=0
_shtab_csi_genie___output_id_nargs=0


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
            print(instance['InstanceId'], instance['PublicIpAddress'], sep='\t')
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

# $1=COMP_WORDS[1]
_shtab_compgen_files() {
  compgen -f -- $1  # files
}

# $1=COMP_WORDS[1]
_shtab_compgen_dirs() {
  compgen -d -- $1  # recurse into subdirs
}

# $1=COMP_WORDS[1]
_shtab_replace_nonword() {
  echo "${1//[^[:word:]]/_}"
}

# set default values (called for the initial parser & any subparsers)
_set_parser_defaults() {
  local subparsers_var="${prefix}_subparsers[@]"
  sub_parsers=${!subparsers_var-}

  local current_option_strings_var="${prefix}_option_strings[@]"
  current_option_strings=${!current_option_strings_var}

  completed_positional_actions=0

  _set_new_action "pos_${completed_positional_actions}" true
}

# $1=action identifier
# $2=positional action (bool)
# set all identifiers for an action's parameters
_set_new_action() {
  current_action="${prefix}_$(_shtab_replace_nonword $1)"

  local current_action_compgen_var=${current_action}_COMPGEN
  current_action_compgen="${!current_action_compgen_var-}"

  local current_action_choices_var="${current_action}_choices[@]"
  current_action_choices="${!current_action_choices_var-}"

  local current_action_nargs_var="${current_action}_nargs"
  if [ -n "${!current_action_nargs_var-}" ]; then
    current_action_nargs="${!current_action_nargs_var}"
  else
    current_action_nargs=1
  fi

  current_action_args_start_index=$(( $word_index + 1 - $pos_only ))

  current_action_is_positional=$2
}

# Notes:
# `COMPREPLY`: what will be rendered after completion is triggered
# `completing_word`: currently typed word to generate completions for
# `${!var}`: evaluates the content of `var` and expand its content as a variable
#     hello="world"
#     x="hello"
#     ${!x} -> ${hello} -> "world"
_shtab_csi() {
  local completing_word="${COMP_WORDS[COMP_CWORD]}"
  local completed_positional_actions
  local current_action
  local current_action_args_start_index
  local current_action_choices
  local current_action_compgen
  local current_action_is_positional
  local current_action_nargs
  local current_option_strings
  local sub_parsers
  COMPREPLY=()

  local prefix=_shtab_csi
  local word_index=0
  local pos_only=0 # "--" delimeter not encountered yet
  _set_parser_defaults
  word_index=1

  # determine what arguments are appropriate for the current state
  # of the arg parser
  while [ $word_index -ne $COMP_CWORD ]; do
    local this_word="${COMP_WORDS[$word_index]}"

    if [[ $pos_only = 1 || " $this_word " != " -- " ]]; then
      if [[ -n $sub_parsers && " ${sub_parsers[@]} " == *" ${this_word} "* ]]; then
        # valid subcommand: add it to the prefix & reset the current action
        prefix="${prefix}_$(_shtab_replace_nonword $this_word)"
        _set_parser_defaults
      fi

      if [[ " ${current_option_strings[@]} " == *" ${this_word} "* ]]; then
        # a new action should be acquired (due to recognised option string or
        # no more input expected from current action);
        # the next positional action can fill in here
        _set_new_action $this_word false
      fi

      if [[ "$current_action_nargs" != "*" ]] && \
         [[ "$current_action_nargs" != "+" ]] && \
         [[ "$current_action_nargs" != *"..." ]] && \
         (( $word_index + 1 - $current_action_args_start_index - $pos_only >= \
            $current_action_nargs )); then
        $current_action_is_positional && let "completed_positional_actions += 1"
        _set_new_action "pos_${completed_positional_actions}" true
      fi
    else
      pos_only=1 # "--" delimeter encountered
    fi

    let "word_index+=1"
  done

  # Generate the completions

  if [[ $pos_only = 0 && "${completing_word}" == -* ]]; then
    # optional argument started: use option strings
    COMPREPLY=( $(compgen -W "${current_option_strings[*]}" -- "${completing_word}") )
  else
    # use choices & compgen
    local IFS=$'\n' # items may contain spaces, so delimit using newline
    COMPREPLY=( $([ -n "${current_action_compgen}" ] \
                  && "${current_action_compgen}" "${completing_word}") )
    unset IFS
    COMPREPLY+=( $(compgen -W "${current_action_choices[*]}" -- "${completing_word}") )
  fi

  return 0
}

complete -o filenames -F _shtab_csi csi
