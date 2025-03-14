# csi

`csi` is a command-line interface for AWS CloudShell.

It allows you to manage and connect to CloudShell sessions from the CLI. It supports VPC and non-VPC sessions.

## Why

When Amazon announced VPC support to CloudShell it quickly became my favourite service.  
Having the ability to spawn a CloudShell session within specific security groups and subnets is extremely useful to troubleshoot issues.

You only pay for data transfer, [no additional fees](https://aws.amazon.com/cloudshell/pricing/), so cost is not of great concern.

Unfortunately, CloudShell is only available on the AWS console, there's no official support in `boto` or the SDKs

Using a terminal in a web browser is sacrilege and also slow, so `csi` brings CloudShell to your terminal where it belongs :)

## Warning

Amazon might be unhappy. Please don't abuse this.

## Setup

1. Install dependencies using `uv` or `pip`
2. If you wish to use `csi ssm` or `csi execute`, you **must** have the [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) somewhere in your `PATH`
3. Run `csi`

## Usage

```
$ csi

usage: csi [-h] [-l {debug,info,warning,error,critical}] {ls,list,create,start,delete,stop,ssm,execute} ...

positional arguments:
  {ls,list,create,start,delete,stop,ssm,execute}
    ls                  List available Cloudshells
    list                List available Cloudshells
    create              Create a new Cloudshell
    start               Start a Cloudshell
    delete              Delete a Cloudshell
    stop                Stop a Cloudshell
    ssm                 SSM to a Cloudshell (requires Session Manager plugin)
    execute             Executes a command on a Cloudshell (requires Session Manager Plugin)

options:
  -h, --help            show this help message and exit
  -l, --log {debug,info,warning,error,critical}
                        Logging level (default: info)
```
