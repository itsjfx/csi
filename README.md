# csi: CloudShell Interface

`csi` is a command-line interface for [AWS CloudShell](https://aws.amazon.com/cloudshell) which brings CloudShell to your terminal where it belongs.

It allows you to manage and connect to VPC and non-VPC CloudShell sessions directly from your command line.

## why CSI?

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
* **Genie** - automatically create a CloudShell with the right network access to reach:
    * hostnames/IP addresses and ports
    * EC2 instances
    * RDS databases

## setup

1. Install dependencies using `uv` or `pip`
2. If you wish to use `csi ssm` or `csi execute`, you **must** have the [AWS Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) somewhere in your `PATH`
3. Run `csi`

## example usage

### Listing CloudShell Environments

```bash
$ csi ls
d4011ed9-eb68-4f9a-9288-aa17b92fce3d  my-environment  vpc-01234567890abcdef  subnet-01234567890abcdef  sg-01234567890abcdef
90356db8-8797-4d97-b776-2fb3696e0132  default
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
$ csi start 90356db8-8797-4d97-b776-2fb3696e0132

# Stop an environment
$ csi stop 90356db8-8797-4d97-b776-2fb3696e0132

# Delete an environment
$ csi delete 90356db8-8797-4d97-b776-2fb3696e0132
```

### Connecting to CloudShell

```bash
# Connect to a CloudShell environment via SSM
$ csi ssm 90356db8-8797-4d97-b776-2fb3696e0132
```

### Executing Commands

```bash
# Run a command on a CloudShell environment
$ csi execute 90356db8-8797-4d97-b776-2fb3696e0132 --cmd "aws s3 ls"
```

### Using Genie Mode

```bash
# Connect to an EC2 instance on port 22
$ csi genie --ec2 i-01234567890abcdef --port 22

# Connect to an RDS instance
$ csi genie --rds my-database-instance

# Connect to a specific IP and port
$ csi genie --ip 10.0.0.123 --port 3306

# Connect to a hostname and port (note this hostname must be externally resolvable)
$ csi genie --host internal-service.example.com --port 8080

# Create a temporary environment that will be deleted after use
$ csi genie --ec2 i-01234567890abcdef --port 22 --tmp
```

## warning

Amazon might be unhappy with this unofficial tool. Please don't abuse it.

Be aware of the [current service quotas](https://docs.aws.amazon.com/general/latest/gr/cloudshell.html#limits_cloudshell) for the service, specifically the adjustable 200 monthly hour limit applied across all IAM principals within an account.

## roadmap

* [x] Inject credentials
* [ ] Upload files
* [ ] Download files
* [x] Genie mode for IP/EC2/RDS access
* [x] Temporary environments
* [ ] Port tunneling
