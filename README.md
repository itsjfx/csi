# csi: CloudShell Interface

`csi` is a command-line interface for [AWS CloudShell](https://aws.amazon.com/cloudshell) which brings CloudShell to your terminal where it belongs.

It allows you to manage and connect to VPC and non-VPC CloudShell sessions directly from your command line.

## Why csi?

Unfortunately, CloudShell is only available on the AWS console. There's no official support in the AWS CLI or any AWS SDK.

The only way to use CloudShell outside of the console is by making [sigv4](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html) signed requests to the correct endpoints.

`csi` handles all these requests for you and provides a sleek interface with custom commands to make CloudShell easier to use.

## why care about cloudshell?

In June 2024, Amazon announced the ability to spin up CloudShell environments in a VPC, subnets, and security groups of your choice.

This is extremely useful for troubleshooting issues:
* boot time is about half a minute, much faster than spinning up an ec2
* environments are ephemeral, which can be useful for testing and quick tasks
* you only pay for data transfer, [no additional fees](https://aws.amazon.com/cloudshell/pricing)

## key features

* **List and manage** CloudShell environments
* **Create VPC environments** with specific VPC, subnets, and security groups
* **Connect** to CloudShell environments via SSM in the terminal
* **Execute commands** remotely on CloudShell environments
* **Genie** - magically creates a CloudShell with the right network access to reach:
    * hostnames/IP addresses and ports
    * EC2 instances
    * RDS databases

## setup

1. Install dependencies using `uv` or `pip`
2. If you wish to use `csi ssm` or `csi execute`, you **must** have the [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) somewhere in your `PATH`
3. Run `csi`

## warnings

* This tool is not an official tool by Amazon/AWS
* Beware of the [service quotas for CloudShell](https://docs.aws.amazon.com/general/latest/gr/cloudshell.html#limits_cloudshell), specifically the adjustable 200 monthly hour limit **applied across all** IAM principals within an account.
* This tool is [GPLv3 licensed](./LICENSE) - there is no warranty. If you reach service limits in your account, contact AWS support.
* CloudShell environments exist per IAM principal. When assuming a role, make sure to do so with a unique role session name for your user.

## example usage

The identifier or name can be used to refer to a CloudShell environment

### Listing CloudShell Environments

```bash
$ csi ls
f2bc9d05-379a-4567-a7e6-8e1d70fbcca4    default RUNNING
47f0d505-bb2b-49b6-9cba-439b57923b53    csi-rds-5432    RUNNING vpc-09453d2535f674519   subnet-0228b118ea7fc7ea0,subnet-0a330e519a4bf3d6f       sg-0ea0e8c8ad969f8be,sg-0ca1d4e7570da9e41
5a856d29-dfb7-4a77-8f48-52d908f93487    csi-10104145-5432       RUNNING vpc-09453d2535f674519   subnet-0228b118ea7fc7ea0        sg-0ea0e8c8ad969f8be,sg-0ca1d4e7570da9e41
```

### Creating a CloudShell Environment

```bash
# Create a default environment
$ csi create

# Create a named environment in a specific VPC
$ csi create --name my-vpc-shell --subnets subnet-01234567890abcdef --security-groups sg-01234567890abcdef
```

### Managing CloudShell Environments

```bash
# Start an environment
$ csi start default
$ csi start 90356db8-8797-4d97-b776-2fb3696e0132

# Stop an environment
$ csi stop default
$ csi stop 90356db8-8797-4d97-b776-2fb3696e0132

# Delete an environment
$ csi delete default
$ csi delete 90356db8-8797-4d97-b776-2fb3696e0132
```

### Connecting to a CloudShell Environment

```bash
# Connect to a CloudShell environment via SSM
$ csi ssm default
```

### Executing Commands on a CloudShell Environment

```bash
# Run a command on a CloudShell environment
$ csi execute default -c 'aws s3 ls'
```

### Using Genie Mode

Genie magically creates a CloudShell with the right network access to reach the resources you need.

Temporary environments can be created with `--tmp`

```bash
# Connect to an EC2 instance on port 22
$ csi genie --ec2 i-01234567890abcdef --port 22

# Connect to an RDS instance
$ csi genie --rds my-database-instance

# Connect to a specific IP and port
$ csi genie --ip 10.0.0.123 --port 3306

# Connect to a hostname and port (note this hostname must be externally resolvable)
$ csi genie --host internal-service.example.com --port 8080

# Create a temporary environment that will be deleted after use with --tmp
$ csi genie --ec2 i-01234567890abcdef --port 22 --tmp
```

## roadmap

* [x] Use name of environment instead of IDs when issuing commands
* [x] Inject credentials
* [x] Upload files
* [x] Download files
* [x] genie: re-use existing environments if the VPC configuration is compatible
* [x] Genie mode for IP/EC2/RDS access
* [x] Temporary environments
* [ ] Port tunneling
