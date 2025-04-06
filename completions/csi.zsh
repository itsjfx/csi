#compdef csi

# AUTOMATICALLY GENERATED by `shtab`


_shtab_csi_commands() {
  local _commands=(
    "create:Create a new CloudShell"
    "delete:Delete a CloudShell"
    "download:Download a file from a CloudShell"
    "execute:Executes a command on a CloudShell"
    "genie:Magically creates a CloudShell with the correct network access to reach the resource you specify"
    "list:List available CloudShells"
    "ls:List available CloudShells"
    "ssm:SSM to a CloudShell"
    "start:Start a CloudShell"
    "stop:Stop a CloudShell"
    "upload:Upload a file to a CloudShell"
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
  "--subnets[Subnet IDs (required for VPC environment)]:subnets:"
  "--security-groups[Security Group IDs (default\: the default security group)]:security_groups:"
)

_shtab_csi_delete_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:"
)

_shtab_csi_download_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:"
  ":File on CloudShell to download:"
  ":Destination path:"
)

_shtab_csi_execute_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  {--cmd,-c}"[]:cmd:"
  ":id:"
)

_shtab_csi_genie_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  "--ip[IP address of ENI]:ip:"
  "--host[Publicly resolvable hostname]:host:"
  "--ec2[EC2 instance ID]:ec2:"
  "--rds[RDS instance ID]:rds:"
  "--port[Port to connect on (optional for --rds)]:port:"
  "--tmp[Clean up CloudShell on exit]"
  "--protocol[IP protocol to connect on (default\: tcp)]:protocol:(tcp udp any)"
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
  ":id:"
)

_shtab_csi_start_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:"
)

_shtab_csi_stop_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:"
)

_shtab_csi_upload_options=(
  "(- : *)"{-h,--help}"[show this help message and exit]"
  ":id:"
  ":File from machine to upload:"
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



typeset -A opt_args

if [[ $zsh_eval_context[-1] == eval ]]; then
  # eval/source/. command, register function for later
  compdef _shtab_csi -N csi
else
  # autoload from fpath, call function directly
  _shtab_csi "$@"
fi
