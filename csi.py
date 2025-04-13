#!/usr/bin/env python3

from concurrent.futures import ThreadPoolExecutor
import shlex
import os
import re
import urllib.parse
import base64
import hashlib
import socket
import ipaddress
import requests
import logging
import signal
import contextlib
import uuid
import botocore
import urllib
import boto3
import botocore.session
import argparse
import sys
import json
import time
import subprocess
from multiprocessing import Process
from functools import cache
from pathlib import Path

DEFAULT_ENVIRONMENT = 'default'

@cache
def aws_client(*args, **kwargs):
    return boto3.client(*args, **kwargs)

def aws_paginate(client, method, **kwargs):
    return aws_client(client).get_paginator(method).paginate(**kwargs)

def shell_quote(cmd):
    return ' '.join(shlex.quote(arg) for arg in cmd)

@cache
def get_region(session=None):
    if not session:
        session = boto3.Session()
    return session.region_name

@cache
def get_cidr_for_subnet(subnet):
    subnet = aws_client('ec2').describe_subnets(SubnetIds=[subnet])
    return subnet['Subnets'][0]['CidrBlock']

def get_default_security_group():
    groups = aws_client('ec2').describe_security_groups(Filters=[{'Name': 'group-name', 'Values': ['default']}])
    if not groups['SecurityGroups']:
        return None
    return groups['SecurityGroups'][0]

def call_api(
    url,
    service=None,
    data=b'',
    method='POST',
    headers=None,
    params=None,
    target=None,
    session=requests,
    boto_session=None,
    **kwargs,
):
    if headers is None:
        headers = {}

    if boto_session is None:
        boto_session = boto3.Session()

    if url and not service:
        _url = urllib.parse.urlparse(url)
        service = _url.netloc.partition('.')[0]

    headers.setdefault('Content-Type', 'application/x-amz-json-1.1')
    if target is not None:
        headers['X-Amz-Target'] = target

    if _json := kwargs.pop('json', None):
        data = json.dumps(_json)

    request = botocore.awsrequest.AWSRequest(method, url, data=data, headers=headers, params=params)
    signer = botocore.auth.SigV4Auth(boto_session.get_credentials(), service, get_region(boto_session))
    signer.add_auth(request)
    response = session.request(
        request.method, request.url, data=request.data, headers=request.headers, params=request.params, **kwargs
    )
    try:
        response.raise_for_status()
    except requests.exceptions.HTTPError as e:
        raise Exception(f'{response.json().get("code")}: {response.json().get("message")}') from e
    return response

def get_vpc_from_subnets(subnets):
    ec2 = aws_client('ec2')
    response = ec2.describe_subnets(SubnetIds=subnets)
    assert len(response['Subnets']) > 0
    vpcs = set(subnet['VpcId'] for subnet in response['Subnets'])

    if len(vpcs) > 1:
        raise ValueError(f'Subnets ({subnets}) are in different VPCs ({vpcs})')

    return list(vpcs)[0]

def console_login_url(session):
    url = 'https://signin.aws.amazon.com/federation'
    dest = 'https://console.aws.amazon.com'
    if not session:
        session = boto3.Session()

    creds = session.get_credentials()
    payload = json.dumps({'sessionId': creds.access_key, 'sessionKey': creds.secret_key, 'sessionToken': creds.token})
    response = requests.get(url, params={'Action': 'getSigninToken', 'Session': payload}).json()

    params = urllib.parse.urlencode({'Action': 'login', 'Destination': dest, 'SigninToken': response['SigninToken']})
    return url + '?' + params

class Cloudshell:
    def __init__(self, session=None):
        if session is None:
            session = boto3.Session()
        self.session = session

    # https://a.b.cdn.console.awsstatic.com/a/v1/F3XUYSJVJOSMATZ5TWLDVDGJUUCOTJW5UGHDFLODSUCMMAQRUWFA/main.js
    def _upload_credentials(self, id):
        session = requests.Session()
        session.get(console_login_url(self.session))

        # crypto.randomUUID() equivalent from JS
        state = str(uuid.uuid4())
        verifier = str(uuid.uuid4()) + str(uuid.uuid4())
        params = urllib.parse.urlencode({'state': state})
        redirect_uri = 'https://auth.cloudshell.ap-southeast-2.aws.amazon.com/callback.js?' + params

        # this code challenge flow is OAuth 2.0 PKCE https://oauth.net/2/pkce
        digest = hashlib.sha256(verifier.encode('utf-8')).digest()
        challenge = base64.urlsafe_b64encode(digest).decode('utf-8').rstrip('=')
        params = {
            'client_id': 'arn:aws:signin:::console/scallop-shell',
            'code_challenge': challenge,
            'code_challenge_method': 'SHA-256',
            'redirect_uri': redirect_uri,
            'response_type': 'code',
        }
        # no need to follow the callback and look into the HTML
        # its exposed in query string of the redirect URL
        url = call_api(
            'https://%s.signin.aws.amazon.com/oauth' % get_region(self.session),
            'signin',
            method='GET',
            session=session,
            params=params,
            allow_redirects=False,
        ).headers['Location']
        query = urllib.parse.urlparse(url).query
        params = urllib.parse.parse_qs(query)
        code = params['code'][0]
        assert state == params['state'][0]
        assert url.startswith(redirect_uri)

        keybase = json.loads(urllib.parse.unquote(session.cookies['aws-userInfo']))['keybase']
        token = self.redeem_code(
            AuthCode=code,
            CodeVerifier=verifier,
            EnvironmentId=id,
            KeyBase=keybase,
            RedirectUri=redirect_uri,
        )['RefreshToken']

        self.put_credentials(EnvironmentId=id, KeyBase=keybase, RefreshToken=token)

    def _execute(self, id, cmd, stdout=sys.stdout):
        cloudshell._start_environment(id)
        data = cloudshell.create_session(EnvironmentId=id, QCliDisabled=True)
        with cloudshell._heart_beat(id):
            proc = subprocess.Popen(
                ['session-manager-plugin', json.dumps(data), get_region(), 'StartSession'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                # stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True,
            )

            prompt = str(uuid.uuid4())
            exit_marker = str(uuid.uuid4())
            wait_for_output(proc, '$')
            proc.stdin.write('PS1=' + prompt + '; HISTFILE=/dev/null\n')
            proc.stdin.flush()
            wait_for_output(proc, prompt)
            proc.stdin.write(cmd + '\n')
            proc.stdin.write('echo ' + exit_marker + '$?\n')
            proc.stdin.flush()

            code = 0
            executed = False
            # TODO handle stderr
            for line in iter(proc.stdout.readline, ''):
                # ignore everything before prompt and cmd
                if prompt in line and cmd in line:
                    executed = True
                elif prompt not in line:
                    # if command is finished
                    if exit_marker in line:
                        code = line.strip().removeprefix(exit_marker)
                        code = int(code)
                        # avoid printing the Exiting session ... stuff
                        executed = False
                        proc.stdin.write('exit\n')
                        proc.stdin.flush()
                    # if command has been executed, but not completed, output all stdout in real time
                    elif executed:
                        stdout.write(line)
                        stdout.flush()
        return code

    def _ssm(self, id):
        cloudshell._start_environment(id)
        cloudshell._upload_credentials(id)
        data = cloudshell.create_session(EnvironmentId=id)
        with ignore_user_entered_signals():
            with cloudshell._heart_beat(id):
                cmd = ['session-manager-plugin', json.dumps(data), get_region(), 'StartSession']
                subprocess.check_call(cmd)

    def _start_environment(self, id):
        data = self.get_environment_status(EnvironmentId=id)
        while True:
            data = self.get_environment_status(EnvironmentId=id)
            logging.info('Environment is %s ...', data['Status'])
            if data['Status'] in {'SUSPENDED'}:
                self.start_environment(EnvironmentId=id)
                time.sleep(3)
            elif data['Status'] in {'RESUMING', 'CREATING', 'SUSPENDING'}:
                time.sleep(1)
            elif data['Status'] == 'RUNNING':
                break
            else:
                raise NotImplementedError(data['Status'])

    def _create_environment(self, name=None, subnets=None, sgs=None, temporary=False):
        data = {}
        if subnets:
            logging.debug('Creating environment: %s with subnets: %r and security groups: %r', name, subnets, sgs)
            vpc = get_vpc_from_subnets(subnets)
            data = {'EnvironmentName': name, 'VpcConfig': {'VpcId': vpc, 'SecurityGroupIds': sgs, 'SubnetIds': subnets}}
        env = self.create_environment(**data)
        id = env['EnvironmentId']
        cloudshell._start_environment(id)
        return id

    @contextlib.contextmanager
    def _use_environment(
        self,
        *args,
        temporary=False,
    ):
        try:
            env = self._create_environment(*args, temporary=temporary)
            yield env
        finally:
            if temporary:
                logging.info('Deleting temporary CloudShell environment...')
                cloudshell.delete_environment(EnvironmentId=env)

    def _send_heart_beat_loop(self, id, timeout=60):
        while True:
            self.send_heart_beat(EnvironmentId=id)
            time.sleep(timeout)

    @contextlib.contextmanager
    def _heart_beat(self, id):
        proc = Process(target=self._send_heart_beat_loop, args=[id])
        proc.start()
        try:
            yield proc
        finally:
            if proc.is_alive():
                proc.terminate()

    @cache
    def _lookup_id(self, id):
        # screw anybody naming environments with a UUID
        try:
            uuid.UUID(id)
            return id
        except ValueError:
            for environment in self.describe_environments()['Environments']:
                name = environment.get('EnvironmentName')
                if environment['EnvironmentId'] == id or (not name and id == DEFAULT_ENVIRONMENT) or name == id:
                    return environment['EnvironmentId']

    # sort of like a real cloudshell client
    def __getattr__(self, attr):
        method = attr.title().replace('_', '')
        method = attr[0] + method[1:]

        def wrapper(EnvironmentId=None, **kwargs):
            service = 'cloudshell'
            region = get_region(self.session)
            url = f'https://{service}.{region}.amazonaws.com/{method}'
            _kwargs = {**kwargs}
            # TODO
            # this is extremely dodgy and i may remove it
            if EnvironmentId:
                _kwargs['EnvironmentId'] = self._lookup_id(EnvironmentId)
            return call_api(url, service, json=_kwargs, boto_session=self.session).json()

        return wrapper

cloudshell = Cloudshell()

def wait_for_output(proc, expected_line):
    for line in iter(proc.stdout.readline, ''):
        if expected_line in line:
            return line

# from
# https://github.com/aws/aws-cli/blob/b31334b1e6dddc3fcffb36fbb82aca0b076520cf/awscli/compat.py#L290
# https://github.com/aws/aws-cli/blob/558d3d4134882003550035724a4c8549771fd79c/awscli/customizations/sessionmanager.py#L148
is_windows = sys.platform == 'win32'
is_macos = sys.platform == 'darwin'

@contextlib.contextmanager
def ignore_user_entered_signals():
    """
    Ignores user entered signals to avoid process getting killed.
    """
    if is_windows:
        signal_list = [signal.SIGINT]
    else:
        signal_list = [signal.SIGINT, signal.SIGQUIT, signal.SIGTSTP]
    actual_signals = []
    for user_signal in signal_list:
        actual_signals.append(signal.signal(user_signal, signal.SIG_IGN))
    try:
        yield
    finally:
        for sig, user_signal in enumerate(signal_list):
            signal.signal(user_signal, actual_signals[sig])

class CLI:
    @staticmethod
    def list(args):
        def job(env):
            status = cloudshell.get_environment_status(env['EnvironmentId'])
            vpc_config = env.get('VpcConfig', {})
            output = [
                env['EnvironmentId'],
                env.get('EnvironmentName', DEFAULT_ENVIRONMENT),
                status['Status'],
                vpc_config.get('VpcId', ''),
                ','.join(vpc_config.get('SubnetIds', '')),
            ]
            if args.security_groups:
                output.append(','.join(vpc_config.get('SecurityGroupIds', '')))
            return output

        def get_details():
            with ThreadPoolExecutor() as executor:
                # this runs multi-threaded but preserves ordering
                for result in executor.map(job, cloudshell.describe_environments()['Environments']):
                    yield result

        if not os.isatty(sys.stdout.fileno()):
            for result in get_details():
                print(*result, sep='\t')
        else:
            rows = list(get_details())
            lengths = [max(len(str(c)) for c in column) for column in zip(*rows)]
            for row in rows:
                print('  '.join(cell.ljust(w) for cell, w in zip(row, lengths)))

    ls = list

    @staticmethod
    def create(args):
        if args.name == DEFAULT_ENVIRONMENT:
            logging.error('You cannot create an environment named %s', DEFAULT_ENVIRONMENT)
            return 2

        if not args.security_groups:
            default = get_default_security_group()
            if not default:
                logging.error(
                    'No default security group found. Please specify at least 1 security group with --security-groups'
                )
                return 3
            args.security_groups = [default['GroupId']]
        response = cloudshell._create_environment(args.name, args.subnets, args.security_groups)
        logging.info('Creating new environment with id: %s', response['EnvironmentId'])

    @staticmethod
    def start(args):
        cloudshell._start_environment(args.id)

    @staticmethod
    def delete(args):
        cloudshell.delete_environment(EnvironmentId=args.id)

    @staticmethod
    def stop(args):
        cloudshell.stop_environment(EnvironmentId=args.id)

    @staticmethod
    def ssm(args):
        cloudshell._ssm(args.id)

    # sort of dodgy
    @staticmethod
    def execute(args):
        return cloudshell._execute(args.id, args.cmd, stdout=sys.stderr)

    @staticmethod
    def upload(args):
        cloudshell._start_environment(args.id)
        data = cloudshell.get_file_upload_urls(EnvironmentId=args.id, FileUploadPath=args.destination)
        url = data['FileUploadPresignedUrl']
        fields = data['FileUploadPresignedFields']
        logging.info('Uploading file ...')
        response = requests.post(url, data={**fields}, files={'file': args.file})
        response.raise_for_status()

        url = data['FileDownloadPresignedUrl']
        algorithm = data['FileUploadPresignedFields']['x-amz-server-side-encryption-customer-algorithm']
        key = data['FileUploadPresignedFields']['x-amz-server-side-encryption-customer-key']

        # allow destinations being a directory
        if args.destination.endswith('/'):
            args.destination += Path(args.file.name).name

        cmd = shell_quote(
            [
                'curl',
                '--silent',
                '--show-error',
                '--fail-with-body',
                url,
                '-o',
                args.destination,
                '-H',
                f'x-amz-server-side-encryption-customer-algorithm: {algorithm}',
                '-H',
                f'x-amz-server-side-encryption-customer-key: {key}',
            ]
        )
        logging.info('Downloading file on CloudShell ...')
        code = cloudshell._execute(args.id, cmd)
        if code:
            logging.error('Download failed')
            return code
        logging.info('Uploaded file to %s on CloudShell', args.destination)

    @staticmethod
    def download(args):
        cloudshell._start_environment(args.id)
        data = cloudshell.get_file_upload_urls(EnvironmentId=args.id, FileUploadPath=args.file)
        url = data['FileUploadPresignedUrl']
        fields = data['FileUploadPresignedFields']
        cmd = shell_quote(
            [
                'curl',
                '-X',
                'POST',
                '--silent',
                '--show-error',
                '--fail-with-body',
                url,
                *[
                    item
                    for k, v in fields.items()
                    for item in (
                        '-F',
                        f'{k}={v}',
                    )
                ],
                '-F',
                f'file=@{args.file}',
            ]
        )

        logging.info('Waiting for CloudShell to upload %s ...', args.file)
        if code := cloudshell._execute(args.id, cmd):
            logging.error('Failed to upload file on CloudShell')
            return code

        # TODO support writing to stdout
        filename = Path(args.file).name
        dest_path = Path(args.destination)

        # allows for destination to be a folder path or file
        # similar to aws s3 cp
        if args.destination.endswith('/') or dest_path.is_dir():
            dest_path.mkdir(parents=True, exist_ok=True)
            dest_path = dest_path / filename
        else:
            dest_path.parent.mkdir(parents=True, exist_ok=True)

        url = data['FileDownloadPresignedUrl']
        headers = {
            'x-amz-server-side-encryption-customer-algorithm': fields[
                'x-amz-server-side-encryption-customer-algorithm'
            ],
            'x-amz-server-side-encryption-customer-key': fields['x-amz-server-side-encryption-customer-key'],
        }
        logging.info('Downloading %s to %s', filename, dest_path)
        chunk_size = 8192
        with requests.get(url, headers=headers, stream=True) as r:
            r.raise_for_status()
            total = int(r.headers.get('Content-Length', 0))

            with open(dest_path, 'wb') as f:
                downloaded = 0
                last_percent = None
                for chunk in r.iter_content(chunk_size=chunk_size):
                    if chunk:
                        f.write(chunk)
                        downloaded += len(chunk)
                        if total:
                            percent = int(downloaded * 100 / total)
                            if percent != last_percent:
                                print(f'\r{percent}%', end='', flush=True, file=sys.stderr)
                                last_percent = percent
        if total:
            print(file=sys.stderr)
        logging.info('Downloaded %s to %s', args.file, dest_path)

    # super messy
    @staticmethod
    def genie(args):
        protocols = {'-1'}  # any
        if args.protocol == 'any':
            protocols.add('tcp')
            protocols.add('udp')
        else:
            protocols.add(args.protocol)

        def find_details_for_ip(ip):
            for page in aws_paginate(
                'ec2', 'describe_network_interfaces', Filters=[{'Name': 'private-ip-address', 'Values': [ip]}]
            ):
                assert len(page['NetworkInterfaces']) == 1
                interface = page['NetworkInterfaces'][0]
                if interface['Status'] == 'in-use' and interface['PrivateIpAddress'] == ip:
                    return interface['VpcId'], [interface['SubnetId']], [i['GroupId'] for i in interface['Groups']]

        def find_details_for_ec2(id):
            for page in aws_paginate('ec2', 'describe_instances', Filters=[{'Name': 'instance-id', 'Values': [id]}]):
                assert len(page['Reservations']) == 1
                assert len(page['Reservations'][0]['Instances']) == 1
                instance = page['Reservations'][0]['Instances'][0]
                # TODO for now only selecting the first ENI, im lazy to add code to check if things are across VPCs
                interface = instance['NetworkInterfaces'][0]
                return interface['VpcId'], [interface['SubnetId']], [i['GroupId'] for i in interface['Groups']]

        def find_details_for_rds(id):
            for page in aws_paginate('rds', 'describe_db_instances', DBInstanceIdentifier=id):
                assert len(page['DBInstances']) == 1
                instance = page['DBInstances'][0]
                return (
                    instance['DBSubnetGroup']['VpcId'],
                    [subnet['SubnetIdentifier'] for subnet in instance['DBSubnetGroup']['Subnets']],
                    [group['VpcSecurityGroupId'] for group in instance['VpcSecurityGroups']],
                    instance['Endpoint']['Address'],
                    instance['Endpoint']['Port'],
                )

        def get_matching_rules(groups):
            for page in aws_paginate('ec2', 'describe_security_groups', GroupIds=groups):
                for group in page['SecurityGroups']:
                    for rule in group['IpPermissions']:
                        if rule['IpProtocol'] in protocols:
                            if ('FromPort' not in rule and 'ToPort' not in rule) or (
                                rule['FromPort'] <= args.port and args.port <= rule['ToPort']
                            ):
                                yield rule

        def filter_security_groups(rules):
            for rule in rules:
                for group in rule['UserIdGroupPairs']:
                    yield group['GroupId']

        def filter_allowed_subnets(rules, subnets):
            for rule in rules:
                for group in rule['IpRanges']:
                    for subnet in subnets:
                        cidr = ipaddress.ip_network(get_cidr_for_subnet(subnet))
                        if cidr.subnet_of(ipaddress.ip_network(group['CidrIp'])):
                            yield subnet

        def get_target_name(target, port):
            MAX_LEN = 28
            HASH_LEN = 6
            name = 'csi-' + re.sub(r'[^a-zA-Z0-9-]', '', f'{target}-{port}')
            logging.debug('environment name: %s', name)
            if len(name) > MAX_LEN:
                logging.debug('name too long, appending hash')
                hash = hashlib.sha256(name.encode()).hexdigest()
                name = name[: MAX_LEN - HASH_LEN - 1] + '-' + hash[:HASH_LEN]
                logging.debug('name with hash: %s', name)
            return name

        if args.host:
            args.ip = socket.gethostbyname(args.host)

        if args.ec2:
            vpc, subnets, groups = find_details_for_ec2(args.ec2)
        elif args.rds:
            vpc, subnets, groups, host, port = find_details_for_rds(args.rds)
            if not args.port:
                args.port = port
        elif args.ip:
            vpc, subnets, groups = find_details_for_ip(args.ip)
        else:
            raise NotImplementedError()

        target = args.ec2 or args.rds or args.ip
        name = get_target_name(target, args.port)

        environments = cloudshell.describe_environments()['Environments']
        for env in environments:
            if env.get('EnvironmentName') == name:
                logging.info('Using existing environment: %s', name)
                cloudshell._ssm(env['EnvironmentId'])
                return

        rules = list(get_matching_rules(groups))
        groups = list(filter_security_groups(rules))

        logging.debug('Security groups: %r', groups)
        if not groups:
            logging.debug('No groups with direct access, looking for whitelisted subnets')
            filtered_subnets = list(filter_allowed_subnets(rules, subnets))
            if not filtered_subnets:
                logging.error('No security groups or subnets allowed to access resource on port %d', args.port)
                return 1
            subnets = filtered_subnets

        default = get_default_security_group()
        if not default:
            logging.warning('No default security group found, CloudShell may be missing egress access')
        else:
            groups.append(default['GroupId'])

        for env in environments:
            vpc_config = env.get('VpcConfig')
            if (
                vpc_config
                and vpc_config['VpcId'] == vpc
                and set(vpc_config['SubnetIds']) == set(subnets)
                and set(vpc_config['SecurityGroupIds']) == set(groups)
            ):
                logging.warning(
                    'Environment: %s has the same VPC config, re-using existing environment',
                    env.get('EnvironmentName', DEFAULT_ENVIRONMENT),
                )
                cloudshell._ssm(env['EnvironmentId'])
                return

        with cloudshell._use_environment(name, subnets, groups, temporary=args.tmp) as id:
            if args.rds:
                logging.info('Connect to RDS on %s:%d', host, port)
            cloudshell._ssm(id)

def completer(name):
    return {'bash': '_csi_complete_' + name, 'zsh': '_csi_complete_' + name}

# for shtab
def make_main_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-l',
        '--log',
        choices=('debug', 'info', 'warning', 'error', 'critical'),
        default='info',
        help='Logging level (default: %(default)s)',
    )

    subparser = parser.add_subparsers(dest='CMD', required=False)

    for cmd in ('ls', 'list'):
        sub = subparser.add_parser(cmd, help='List available CloudShells')
        sub.add_argument('--security-groups', action='store_true', help='Display security groups in output')

    sub = subparser.add_parser('create', help='Create a new CloudShell')
    sub.add_argument('--name', required=False, help='Name for environment (required for VPC environment)')
    sub.add_argument('--subnets', nargs='*', help='Subnet IDs (required for VPC environment)').complete = completer(
        'subnets'
    )
    sub.add_argument(
        '--security-groups', nargs='*', help='Security Group IDs (default: the default security group)'
    ).complete = completer('sgs')

    sub = subparser.add_parser('start', help='Start a CloudShell')
    sub.add_argument('id').complete = completer('cloudshell_suspended')

    sub = subparser.add_parser('delete', help='Delete a CloudShell')
    sub.add_argument('id').complete = completer('cloudshell')

    sub = subparser.add_parser('stop', help='Stop a CloudShell')
    sub.add_argument('id').complete = completer('cloudshell_running')

    sub = subparser.add_parser('ssm', help='SSM to a CloudShell')
    sub.add_argument('id').complete = completer('cloudshell')

    sub = subparser.add_parser('execute', help='Executes a command on a CloudShell')
    sub.add_argument('id').complete = completer('cloudshell')
    sub.add_argument('--cmd', '-c', required=True)

    sub = subparser.add_parser('upload', help='Upload a file to a CloudShell')
    sub.add_argument('id').complete = completer('cloudshell')
    sub.add_argument('file', type=argparse.FileType('rb'), help='File from machine to upload').complete = completer(
        'files'
    )
    sub.add_argument('destination', help='Destination path')

    sub = subparser.add_parser('download', help='Download a file from a CloudShell')
    sub.add_argument('id').complete = completer('cloudshell')
    sub.add_argument('file', help='File on CloudShell to download')
    # purposefully not making a Path cause it messes when trying to figure out things are directories
    sub.add_argument('destination', help='Destination path').complete = completer('files')

    sub = subparser.add_parser(
        'genie', help='Magically creates a CloudShell with the correct network access to reach the resource you specify'
    )
    group = sub.add_mutually_exclusive_group(required=True)
    group.add_argument('--ip', help='IP address of ENI').complete = completer('eni')
    group.add_argument('--host', help='Publicly resolvable hostname')
    group.add_argument('--ec2', help='EC2 instance ID').complete = completer('ec2')
    group.add_argument('--rds', help='RDS instance ID').complete = completer('rds')

    sub.add_argument('--port', type=int, help='Port to connect on (optional for --rds)')
    sub.add_argument('--tmp', action='store_true', help='Clean up CloudShell on exit')
    sub.add_argument(
        '--protocol',
        choices=('tcp', 'udp', 'any'),
        default='tcp',
        help='IP protocol to connect on (default: %(default)s)',
    )

    # clean up the usage line
    subs = next(action for action in parser._actions if isinstance(action, argparse._SubParsersAction))
    subcmds = list(subs.choices.keys())
    parser.usage = f'{parser.prog} [options] {{{",".join(subcmds)}}} ...'

    # add description for each subparser so shtab works
    for action in parser._subparsers._actions:
        if isinstance(action, argparse._SubParsersAction):
            for name, subparser in action.choices.items():
                help_text = next((a.help for a in action._choices_actions if a.dest == name), None)
                if help_text:
                    subparser.description = help_text
    return parser

def main():
    parser = make_main_parser()
    args = parser.parse_args()
    if not args.CMD:
        parser.print_help()
        return

    if args.CMD == 'create':
        if args.subnets and not args.name:
            parser.error('--name is required if creating a VPC CloudShell')
        if not args.subnets and args.name:
            parser.error('--subnets must be set if setting name')

    if args.CMD == 'genie':
        if (args.ec2 or args.ip or args.host) and not args.port:
            parser.error('--port is required')

    level = getattr(logging, args.log.upper())
    logging.basicConfig(level=level, format='%(levelname)s\t%(message)s')
    # TODO
    boto3.set_stream_logger('boto3', level=level + 1)
    boto3.set_stream_logger('botocore', level=level + 1)
    boto3.set_stream_logger('urllib3', level=level + 1)

    return getattr(CLI, args.CMD.replace('-', '_'))(args)

if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
