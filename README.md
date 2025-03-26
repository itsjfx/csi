# csi

`csi` is a command-line interface for [AWS CloudShell](https://aws.amazon.com/cloudshell).

It allows you to manage and connect to VPC and non-VPC CloudShell sessions from the CLI.

## why

Unfortunately, CloudShell is only available on the AWS console. There's no official support in the AWS CLI or any AWS SDK.

The only way to use CloudShell outside of the console is by making [sigv4](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html) signed requests to the correct endpoints.

`csi` will handle all the requests for you and aims to provide a sleek interface with some custom commands to make it easier to use CloudShell.

Using a terminal in a web browser is sacrilege - `csi` brings CloudShell to your terminal where it belongs :)

## why care about CloudShell?

In June 2024, Amazon announced the ability to spin up CloudShell environments in a VPC, subnets, and security groups of your choice.

This is extremely useful to troubleshoot issues. The boot time is about half a minute, so much faster than spinning up an  EC2. The environment is also ephemeral which can be useful.

You only pay for data transfer, [no additional fees](https://aws.amazon.com/cloudshell/pricing/), so cost is not of great concern.

## warning

Amazon might be unhappy. Please don't abuse this.

## TODO

* [ ] inject credentials
* [ ] uploading files
* [ ] downloading files
* [x] gimme shell to IP + port or instance ID + port or RDS or RDS + port (GENIE)
* [ ] temp environments
* [ ] temp environments + temp principals/roles
* [ ] tunnel?

## setup

1. Install dependencies using `uv` or `pip`
2. If you wish to use `csi ssm` or `csi execute`, you **must** have the [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) somewhere in your `PATH`
3. Run `csi`

## Usage

```
$ csi

usage: csi [-h] [-l {debug,info,warning,error,critical}] {ls,list,create,start,delete,stop,ssm,execute,genie} ...

positional arguments:
  {ls,list,create,start,delete,stop,ssm,execute,genie}
    ls                  List available Cloudshells
    list                List available Cloudshells
    create              Create a new Cloudshell
    start               Start a Cloudshell
    delete              Delete a Cloudshell
    stop                Stop a Cloudshell
    ssm                 SSM to a Cloudshell (requires Session Manager plugin)
    execute             Executes a command on a Cloudshell (requires Session Manager Plugin)
    genie               Magically gives you a Cloudshell with the right access in your VPC

options:
  -h, --help            show this help message and exit
  -l, --log {debug,info,warning,error,critical}
                        Logging level (default: info)
```
