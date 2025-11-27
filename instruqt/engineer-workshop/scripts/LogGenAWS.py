import json
import time
import random
import socket
import sys
from datetime import datetime, timedelta
from typing import Dict, List

class AWSRawLogGenerator:
    """
    Generates raw AWS logs in native formats (CloudWatch, CloudTrail, VPC Flow, etc.)
    with optional threat intelligence enhancements for Graylog ingestion
    """
    
    def __init__(self, environment="production", region="us-east-1", enable_threat_intel=False):
        self.environment = environment
        self.region = region
        self.enable_threat_intel = enable_threat_intel
        self.aws_account_id = f"{random.randint(100000000000, 999999999999)}"
        self.vpc_id = f"vpc-{self._random_hex(17)}"
        
        self.log_types = {
            "cloudwatch": self._generate_cloudwatch_raw,
            "cloudtrail": self._generate_cloudtrail_raw,
            "vpc_flow": self._generate_vpc_flow_raw,
            "elb_access": self._generate_elb_access_raw,
            "s3_access": self._generate_s3_access_raw,
            "rds_logs": self._generate_rds_raw,
            "waf_logs": self._generate_waf_raw,
            "guardduty": self._generate_guardduty_raw,
            "auth_logs": self._generate_auth_raw,
            "application": self._generate_application_raw
        }
    
    def _random_hex(self, length: int) -> str:
        return ''.join(random.choices('0123456789abcdef', k=length))
    
    def _generate_public_ip(self, suspicious: bool = False) -> str:
        """Generate realistic public IPs - AWS ranges vs suspicious ranges"""
        if suspicious:
            # Known suspicious IP ranges
            ranges = [
                (185, random.randint(10, 220)),  # Russian ranges
                (45, random.randint(10, 142)),   # Chinese ranges
                (103, random.randint(10, 255)),  # Asian ranges
                (194, random.randint(10, 255)),  # Eastern European
                (37, random.randint(10, 255)),   # Various threat actors
            ]
            first, second = random.choice(ranges)
            return f"{first}.{second}.{random.randint(0,255)}.{random.randint(1,254)}"
        else:
            # AWS/legitimate public ranges
            aws_first = random.choice([3, 13, 18, 34, 35, 44, 52, 54, 99, 107])
            return f"{aws_first}.{random.randint(0,255)}.{random.randint(0,255)}.{random.randint(1,254)}"
    
    def _generate_threat_intel(self, ip: str) -> Dict:
        """
        Generate threat intelligence metadata for IP correlation
        Only included if enable_threat_intel=True
        """
        if not self.enable_threat_intel:
            return {}
        
        is_suspicious = ip.startswith(('185.', '45.', '103.', '194.', '37.'))
        
        threat_intel = {
            "threat_score": random.randint(65, 95) if is_suspicious else random.randint(0, 30),
            "geo_country": random.choice(["RU", "CN", "KP", "IR", "BY"]) if is_suspicious else random.choice(["US", "GB", "DE", "FR", "CA"]),
            "geo_city": random.choice(["Moscow", "Beijing", "Pyongyang", "Tehran"]) if is_suspicious else random.choice(["Seattle", "London", "Frankfurt", "Paris"]),
            "asn": f"AS{random.randint(10000, 99999)}",
            "isp": "Unknown" if is_suspicious else random.choice(["AWS", "Azure", "Google Cloud", "Digital Ocean"]),
            "is_tor": random.random() < 0.1 if is_suspicious else False,
            "is_proxy": random.random() < 0.2 if is_suspicious else False,
            "is_vpn": random.random() < 0.3 if is_suspicious else False,
            "reputation_score": random.randint(1, 3) if is_suspicious else random.randint(8, 10),
            "threat_categories": random.sample(["bruteforce", "scanner", "malware", "botnet", "spam"], k=random.randint(0, 2)) if is_suspicious else []
        }
        
        return threat_intel
    
    def _generate_cloudwatch_raw(self) -> Dict:
        """Raw CloudWatch log format"""
        timestamp = datetime.utcnow()
        log_stream = f"i-{self._random_hex(17)}/{timestamp.strftime('%Y/%m/%d')}/[{random.randint(0,9)}]"
        
        messages = [
            f"[ERROR] Failed to connect to database: Connection timeout",
            f"[INFO] Application started successfully on port 8080",
            f"[WARN] High memory usage detected: 87%",
            f"[ERROR] Unhandled exception in request handler",
            f"[INFO] User session created",
            f"[WARN] API rate limit approaching threshold"
        ]
        
        return {
            "messageType": "DATA_MESSAGE",
            "owner": self.aws_account_id,
            "logGroup": f"/aws/ec2/{self.environment}",
            "logStream": log_stream,
            "subscriptionFilters": ["lab-research-filter"],
            "logEvents": [{
                "id": self._random_hex(56),
                "timestamp": int(timestamp.timestamp() * 1000),
                "message": random.choice(messages)
            }]
        }
    
    def _generate_cloudtrail_raw(self) -> Dict:
        """Raw AWS CloudTrail log format"""
        timestamp = datetime.utcnow().isoformat() + 'Z'
        source_ip = self._generate_public_ip(suspicious=random.random() < 0.12)
        
        events = [
            "CreateBucket", "DeleteBucket", "PutBucketPolicy", "GetObject",
            "RunInstances", "TerminateInstances", "AuthorizeSecurityGroupIngress",
            "CreateAccessKey", "DeleteAccessKey", "AttachUserPolicy", "DetachUserPolicy",
            "CreateUser", "DeleteUser", "GetSecretValue", "PutSecretValue"
        ]
        
        event_name = random.choice(events)
        is_root = random.random() < 0.05
        error_code = random.choice([None, "AccessDenied", "UnauthorizedOperation"]) if random.random() < 0.15 else None
        
        record = {
            "eventVersion": "1.08",
            "userIdentity": {
                "type": "Root" if is_root else random.choice(["IAMUser", "AssumedRole", "FederatedUser"]),
                "principalId": f"AIDA{'ROOT' if is_root else self._random_hex(18).upper()}",
                "arn": f"arn:aws:iam::{self.aws_account_id}:{'root' if is_root else 'user/researcher-' + str(random.randint(1,100))}",
                "accountId": self.aws_account_id,
                "userName": "root" if is_root else f"researcher-{random.randint(1,100)}"
            },
            "eventTime": timestamp,
            "eventSource": f"{random.choice(['s3', 'ec2', 'iam', 'secretsmanager', 'rds'])}.amazonaws.com",
            "eventName": event_name,
            "awsRegion": self.region,
            "sourceIPAddress": source_ip,
            "userAgent": random.choice([
                "aws-cli/2.13.0 Python/3.11.4",
                "console.aws.amazon.com",
                "Boto3/1.28.0 Python/3.9.0",
                "aws-sdk-go/1.44.0"
            ]),
            "requestParameters": {
                "bucketName": f"lab-data-{random.randint(100,999)}" if "Bucket" in event_name else None,
                "instanceType": "t3.medium" if "Instances" in event_name else None
            },
            "responseElements": None if error_code else {"requestId": self._random_hex(36)},
            "requestID": self._random_hex(36),
            "eventID": self._random_hex(36),
            "readOnly": event_name.startswith(("Get", "List", "Describe")),
            "eventType": "AwsApiCall",
            "managementEvent": True,
            "recipientAccountId": self.aws_account_id,
            "errorCode": error_code,
            "errorMessage": "Access Denied" if error_code == "AccessDenied" else None
        }
        
        # Add threat intel only if enabled
        threat_intel = self._generate_threat_intel(source_ip)
        if threat_intel:
            record["threat_intel"] = threat_intel
        
        return {"Records": [record]}
    
    def _generate_vpc_flow_raw(self) -> str:
        """Raw VPC Flow Log format (space-delimited)"""
        source_ip = self._generate_public_ip(suspicious=random.random() < 0.18)
        dest_ip = self._generate_public_ip(suspicious=False)
        
        action = random.choices(["ACCEPT", "REJECT"], weights=[75, 25])[0]
        protocol = random.choice([6, 17, 1])  # TCP, UDP, ICMP
        
        # VPC Flow Log format version 2
        fields = [
            "2",  # version
            self.aws_account_id,
            f"eni-{self._random_hex(17)}",
            source_ip,
            dest_ip,
            str(random.randint(1024, 65535)),  # srcport
            str(random.choice([22, 80, 443, 3306, 5432, 3389, 8080])),  # dstport
            str(protocol),
            str(random.randint(1, 1000)),  # packets
            str(random.randint(1000, 1000000)),  # bytes
            str(int(datetime.utcnow().timestamp())),  # start
            str(int(datetime.utcnow().timestamp()) + random.randint(1, 300)),  # end
            action,
            "OK"  # log-status
        ]
        
        # Add threat intel as JSON in custom field only if enabled
        log_data = {
            "vpc_flow_log": " ".join(fields),
            "parsed": {
                "version": 2,
                "account_id": self.aws_account_id,
                "interface_id": fields[2],
                "source_ip": source_ip,
                "destination_ip": dest_ip,
                "source_port": int(fields[5]),
                "destination_port": int(fields[6]),
                "protocol": protocol,
                "action": action
            }
        }
        
        threat_intel = self._generate_threat_intel(source_ip)
        if threat_intel:
            log_data["threat_intel"] = threat_intel
        
        return log_data
    
    def _generate_elb_access_raw(self) -> str:
        """Raw ELB Access Log format"""
        timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
        client_ip = self._generate_public_ip(suspicious=random.random() < 0.15)
        
        status_codes = random.choices(
            [200, 201, 204, 301, 302, 400, 401, 403, 404, 500, 502, 503],
            weights=[50, 5, 5, 3, 3, 5, 5, 8, 8, 3, 2, 3]
        )[0]
        
        log_line = f'https {timestamp} app/lab-research-elb/{self._random_hex(16)} ' \
                   f'{client_ip}:{random.randint(40000, 65535)} ' \
                   f'10.0.{random.randint(1,255)}.{random.randint(1,255)}:{random.choice([80, 8080, 443])} ' \
                   f'{random.uniform(0.001, 2.5):.3f} {random.uniform(0.001, 0.5):.3f} {random.uniform(0.001, 0.5):.3f} ' \
                   f'{status_codes} {status_codes} {random.randint(100, 5000)} {random.randint(500, 50000)} ' \
                   f'"GET https://lab-api.example.com:443/{random.choice(["api/data", "api/auth", "api/samples", "api/results"])} HTTP/1.1" ' \
                   f'"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" ' \
                   f'ECDHE-RSA-AES128-GCM-SHA256 TLSv1.2'
        
        log_data = {
            "elb_log": log_line,
            "parsed": {
                "timestamp": timestamp,
                "client_ip": client_ip,
                "status_code": status_codes,
                "backend_status_code": status_codes
            }
        }
        
        threat_intel = self._generate_threat_intel(client_ip)
        if threat_intel:
            log_data["threat_intel"] = threat_intel
        
        return log_data
    
    def _generate_s3_access_raw(self) -> str:
        """Raw S3 Access Log format"""
        timestamp = datetime.utcnow().strftime('%d/%b/%Y:%H:%M:%S +0000')
        remote_ip = self._generate_public_ip(suspicious=random.random() < 0.10)
        
        operations = ["REST.GET.OBJECT", "REST.PUT.OBJECT", "REST.DELETE.OBJECT", "REST.GET.BUCKET"]
        operation = random.choice(operations)
        status = random.choices([200, 204, 403, 404, 500], weights=[70, 10, 10, 5, 5])[0]
        
        log_line = f'{self._random_hex(16)} lab-research-bucket-{random.randint(100,999)} ' \
                   f'[{timestamp}] {remote_ip} {self._random_hex(16)} {self._random_hex(8)} ' \
                   f'{operation} /sample-data/experiment-{random.randint(1000,9999)}.csv ' \
                   f'"{operation} /sample-data/experiment-{random.randint(1000,9999)}.csv HTTP/1.1" ' \
                   f'{status} - {random.randint(100, 10000000)} {random.randint(100, 10000000)} ' \
                   f'{random.randint(10, 5000)} {random.randint(10, 5000)} "-" ' \
                   f'"aws-cli/2.13.0" - {self._random_hex(16)} SigV4 ECDHE-RSA-AES128-GCM-SHA256 ' \
                   f'AuthHeader lab-research-bucket-{random.randint(100,999)}.s3.{self.region}.amazonaws.com TLSv1.2'
        
        log_data = {
            "s3_log": log_line,
            "parsed": {
                "timestamp": timestamp,
                "remote_ip": remote_ip,
                "operation": operation,
                "status_code": status
            }
        }
        
        threat_intel = self._generate_threat_intel(remote_ip)
        if threat_intel:
            log_data["threat_intel"] = threat_intel
        
        return log_data
    
    def _generate_rds_raw(self) -> str:
        """Raw RDS database log format"""
        timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
        
        log_types = [
            f"{timestamp} UTC:[{random.randint(1000,9999)}]:LOG: connection received: host={self._generate_public_ip(suspicious=random.random() < 0.08)} port={random.randint(40000,65535)}",
            f"{timestamp} UTC:[{random.randint(1000,9999)}]:LOG: connection authorized: user=labuser database=research_db",
            f"{timestamp} UTC:[{random.randint(1000,9999)}]:ERROR: permission denied for table sensitive_data",
            f"{timestamp} UTC:[{random.randint(1000,9999)}]:LOG: statement: SELECT * FROM experiments WHERE id = {random.randint(1,1000)}",
            f"{timestamp} UTC:[{random.randint(1000,9999)}]:WARNING: too many authentication failures"
        ]
        
        return {"rds_log": random.choice(log_types)}
    
    def _generate_waf_raw(self) -> Dict:
        """Raw AWS WAF log format (JSON)"""
        timestamp = int(datetime.utcnow().timestamp() * 1000)
        client_ip = self._generate_public_ip(suspicious=random.random() < 0.25)
        
        action = random.choices(["ALLOW", "BLOCK", "COUNT"], weights=[65, 30, 5])[0]
        
        waf_log = {
            "timestamp": timestamp,
            "formatVersion": 1,
            "webaclId": f"arn:aws:wafv2:{self.region}:{self.aws_account_id}:regional/webacl/lab-research-waf/{self._random_hex(36)}",
            "terminatingRuleId": "Default_Action" if action == "ALLOW" else f"rule-{random.randint(1,10)}",
            "terminatingRuleType": "REGULAR" if action != "ALLOW" else "GROUP",
            "action": action,
            "terminatingRuleMatchDetails": [],
            "httpSourceName": "ALB",
            "httpSourceId": f"{self.aws_account_id}-app/lab-research-alb/{self._random_hex(16)}",
            "ruleGroupList": [],
            "rateBasedRuleList": [],
            "nonTerminatingMatchingRules": [],
            "requestHeadersInserted": [],
            "responseCodeSent": random.choice([200, 403]),
            "httpRequest": {
                "clientIp": client_ip,
                "country": "RU" if client_ip.startswith(('185.', '194.')) else "US",
                "headers": [
                    {"name": "Host", "value": "lab-api.example.com"},
                    {"name": "User-Agent", "value": "Mozilla/5.0 (Windows NT 10.0)"}
                ],
                "uri": f"/api/{random.choice(['data', 'auth', 'query', 'upload'])}",
                "args": "",
                "httpVersion": "HTTP/1.1",
                "httpMethod": random.choice(["GET", "POST", "PUT", "DELETE"]),
                "requestId": self._random_hex(16)
            }
        }
        
        threat_intel = self._generate_threat_intel(client_ip)
        if threat_intel:
            waf_log["threat_intel"] = threat_intel
        
        return waf_log
    
    def _generate_guardduty_raw(self) -> Dict:
        """Raw AWS GuardDuty finding format"""
        source_ip = self._generate_public_ip(suspicious=True)
        
        finding_types = [
            "Recon:EC2/PortProbeUnprotectedPort",
            "UnauthorizedAccess:EC2/SSHBruteForce",
            "Backdoor:EC2/C&CActivity.B!DNS",
            "CryptoCurrency:EC2/BitcoinTool.B!DNS",
            "Trojan:EC2/BlackholeTraffic",
            "UnauthorizedAccess:IAMUser/MaliciousIPCaller.Custom"
        ]
        
        guardduty_finding = {
            "schemaVersion": "2.0",
            "accountId": self.aws_account_id,
            "region": self.region,
            "partition": "aws",
            "id": self._random_hex(32),
            "arn": f"arn:aws:guardduty:{self.region}:{self.aws_account_id}:detector/{self._random_hex(32)}/finding/{self._random_hex(32)}",
            "type": random.choice(finding_types),
            "resource": {
                "resourceType": "Instance",
                "instanceDetails": {
                    "instanceId": f"i-{self._random_hex(17)}",
                    "instanceType": "t3.medium",
                    "availabilityZone": f"{self.region}a",
                    "imageId": f"ami-{self._random_hex(17)}"
                }
            },
            "service": {
                "serviceName": "guardduty",
                "detectorId": self._random_hex(32),
                "action": {
                    "actionType": "NETWORK_CONNECTION",
                    "networkConnectionAction": {
                        "connectionDirection": "INBOUND",
                        "remoteIpDetails": {
                            "ipAddressV4": source_ip,
                            "organization": {"asn": str(random.randint(10000, 99999))},
                            "country": {"countryName": "Russia" if source_ip.startswith('185.') else "China"},
                            "city": {"cityName": "Moscow" if source_ip.startswith('185.') else "Beijing"}
                        },
                        "remotePortDetails": {"port": random.choice([22, 3389, 445])},
                        "localPortDetails": {"port": random.choice([22, 3389, 445])},
                        "protocol": "TCP"
                    }
                },
                "eventFirstSeen": datetime.utcnow().isoformat() + 'Z',
                "eventLastSeen": datetime.utcnow().isoformat() + 'Z',
                "archived": False,
                "count": random.randint(1, 50)
            },
            "severity": random.uniform(4.0, 8.9),
            "createdAt": datetime.utcnow().isoformat() + 'Z',
            "updatedAt": datetime.utcnow().isoformat() + 'Z',
            "title": "SSH brute force attack detected",
            "description": f"EC2 instance {random.randint(1,100)} is performing SSH brute force attacks."
        }
        
        threat_intel = self._generate_threat_intel(source_ip)
        if threat_intel:
            guardduty_finding["threat_intel"] = threat_intel
        
        return guardduty_finding
    
    def _generate_auth_raw(self) -> str:
        """Raw Linux auth.log / secure log format"""
        timestamp = datetime.utcnow().strftime('%b %d %H:%M:%S')
        source_ip = self._generate_public_ip(suspicious=random.random() < 0.20)
        
        auth_events = [
            f"{timestamp} ip-10-0-1-{random.randint(1,255)} sshd[{random.randint(1000,9999)}]: Failed password for researcher from {source_ip} port {random.randint(40000,65535)} ssh2",
            f"{timestamp} ip-10-0-1-{random.randint(1,255)} sshd[{random.randint(1000,9999)}]: Accepted publickey for ubuntu from {source_ip} port {random.randint(40000,65535)} ssh2",
            f"{timestamp} ip-10-0-1-{random.randint(1,255)} sudo: researcher : TTY=pts/0 ; PWD=/home/researcher ; USER=root ; COMMAND=/bin/bash",
            f"{timestamp} ip-10-0-1-{random.randint(1,255)} sshd[{random.randint(1000,9999)}]: Invalid user admin from {source_ip} port {random.randint(40000,65535)}",
            f"{timestamp} ip-10-0-1-{random.randint(1,255)} sshd[{random.randint(1000,9999)}]: Connection closed by {source_ip} port {random.randint(40000,65535)} [preauth]"
        ]
        
        log_data = {
            "auth_log": random.choice(auth_events)
        }
        
        threat_intel = self._generate_threat_intel(source_ip)
        if threat_intel:
            log_data["threat_intel"] = threat_intel
        
        return log_data
    
    def _generate_application_raw(self) -> Dict:
        """Raw application log format (JSON structured)"""
        timestamp = datetime.utcnow().isoformat() + 'Z'
        source_ip = self._generate_public_ip(suspicious=random.random() < 0.12)
        
        levels = ["INFO", "WARN", "ERROR", "DEBUG", "FATAL"]
        actions = ["user_login", "data_access", "api_call", "data_export", "config_change"]
        
        level = random.choices(levels, weights=[50, 25, 15, 8, 2])[0]
        action = random.choice(actions)
        
        app_log = {
            "@timestamp": timestamp,
            "level": level,
            "logger": "com.lab.research.Application",
            "thread": f"http-nio-8080-exec-{random.randint(1,10)}",
            "message": f"User action: {action}",
            "context": {
                "user_id": f"user-{random.randint(1,500)}",
                "session_id": self._random_hex(32),
                "request_id": self._random_hex(32),
                "action": action,
                "source_ip": source_ip,
                "user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
                "response_time_ms": random.randint(10, 2000),
                "status_code": random.choice([200, 201, 400, 401, 403, 500])
            }
        }
        
        threat_intel = self._generate_threat_intel(source_ip)
        if threat_intel:
            app_log["threat_intel"] = threat_intel
        
        return app_log
    
    def generate_log_batch(self, count: int = 100, distribution: Dict = None) -> List[Dict]:
        """Generate batch of raw logs with specified distribution"""
        if distribution is None:
            distribution = {
                "cloudtrail": 20,
                "vpc_flow": 25,
                "auth_logs": 15,
                "application": 15,
                "elb_access": 10,
                "guardduty": 5,
                "waf_logs": 5,
                "s3_access": 3,
                "cloudwatch": 1,
                "rds_logs": 1
            }
        
        logs = []
        for log_type, percentage in distribution.items():
            log_count = int(count * (percentage / 100))
            for _ in range(log_count):
                logs.append(self.log_types[log_type]())
        
        return logs
    
    def export_to_graylog_format(self, logs: List, filename: str = "aws_raw_logs.json"):
        """Export logs in GELF format for Graylog"""
        with open(filename, 'w') as f:
            for log in logs:
                # Convert to GELF format
                gelf_log = {
                    "version": "1.1",
                    "host": log.get("parsed", {}).get("source_ip", self._generate_public_ip()),
                    "short_message": str(log),
                    "timestamp": datetime.utcnow().timestamp(),
                    "level": 6,
                    "_raw_log": json.dumps(log),
                    "_log_type": self._identify_log_type(log),
                    "_aws_account": self.aws_account_id,
                    "_aws_region": self.region
                }
                
                # Add threat intel if present
                if "threat_intel" in log:
                    for key, value in log["threat_intel"].items():
                        gelf_log[f"_threat_{key}"] = value
                
                f.write(json.dumps(gelf_log) + '\n')
        
        print(f"Exported {len(logs)} raw logs to {filename}")
    
    def send_to_graylog(self, logs: List, graylog_host: str, graylog_port: int = 12201, protocol: str = "udp"):
        """
        Send logs directly to Graylog server
        
        Args:
            logs: List of log dictionaries
            graylog_host: Graylog server hostname or IP
            graylog_port: Graylog GELF input port (default: 12201 for UDP, 12201 for TCP)
            protocol: 'udp' or 'tcp' (default: udp)
        """
        sent_count = 0
        failed_count = 0
        
        try:
            if protocol.lower() == "udp":
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                print(f"Sending logs to Graylog via UDP: {graylog_host}:{graylog_port}")
                
                for log in logs:
                    try:
                        # Convert to GELF format
                        gelf_log = {
                            "version": "1.1",
                            "host": log.get("parsed", {}).get("source_ip", self._generate_public_ip()),
                            "short_message": json.dumps(log)[:200],  # Truncate for short_message
                            "timestamp": datetime.utcnow().timestamp(),
                            "level": 6,
                            "_raw_log": json.dumps(log),
                            "_log_type": self._identify_log_type(log),
                            "_aws_account": self.aws_account_id,
                            "_aws_region": self.region
                        }
                        
                        # Add threat intel if present
                        if "threat_intel" in log:
                            for key, value in log["threat_intel"].items():
                                gelf_log[f"_threat_{key}"] = value
                        
                        message = json.dumps(gelf_log).encode('utf-8')
                        
                        # UDP has max size, split if needed (GELF supports chunking but simplified here)
                        if len(message) > 8192:
                            message = message[:8192]
                        
                        sock.sendto(message, (graylog_host, graylog_port))
                        sent_count += 1
                        
                        # Small delay to avoid overwhelming the server
                        if sent_count % 100 == 0:
                            time.sleep(0.1)
                            print(f"  Sent {sent_count}/{len(logs)} logs...")
                        
                    except Exception as e:
                        failed_count += 1
                        if failed_count <= 5:  # Only print first few errors
                            print(f"  Error sending log: {e}")
                
                sock.close()
                
            elif protocol.lower() == "tcp":
                print(f"Sending logs to Graylog via TCP: {graylog_host}:{graylog_port}")
                
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.connect((graylog_host, graylog_port))
                
                for log in logs:
                    try:
                        gelf_log = {
                            "version": "1.1",
                            "host": log.get("parsed", {}).get("source_ip", self._generate_public_ip()),
                            "short_message": json.dumps(log)[:200],
                            "timestamp": datetime.utcnow().timestamp(),
                            "level": 6,
                            "_raw_log": json.dumps(log),
                            "_log_type": self._identify_log_type(log),
                            "_aws_account": self.aws_account_id,
                            "_aws_region": self.region
                        }
                        
                        if "threat_intel" in log:
                            for key, value in log["threat_intel"].items():
                                gelf_log[f"_threat_{key}"] = value
                        
                        message = json.dumps(gelf_log).encode('utf-8')
                        # TCP GELF requires null-byte termination
                        sock.sendall(message + b'\0')
                        sent_count += 1
                        
                        if sent_count % 100 == 0:
                            print(f"  Sent {sent_count}/{len(logs)} logs...")
                        
                    except Exception as e:
                        failed_count += 1
                        if failed_count <= 5:
                            print(f"  Error sending log: {e}")
                
                sock.close()
            
            else:
                print(f"Error: Unsupported protocol '{protocol}'. Use 'udp' or 'tcp'.")
                return
            
            print(f"\n✓ Successfully sent {sent_count} logs to Graylog")
            if failed_count > 0:
                print(f"✗ Failed to send {failed_count} logs")
                
        except socket.gaierror:
            print(f"✗ Error: Could not resolve hostname '{graylog_host}'")
        except socket.error as e:
            print(f"✗ Socket error: {e}")
        except Exception as e:
            print(f"✗ Unexpected error: {e}")
    
    def _identify_log_type(self, log: Dict) -> str:
        """Identify log type from structure"""
        if "Records" in log:
            return "cloudtrail"
        elif "vpc_flow_log" in log:
            return "vpc_flow"
        elif "elb_log" in log:
            return "elb_access"
        elif "s3_log" in log:
            return "s3_access"
        elif "rds_log" in log:
            return "rds"
        elif "webaclId" in log:
            return "waf"
        elif "type" in log and "guardduty" in str(log.get("service", {})):
            return "guardduty"
        elif "auth_log" in log:
            return "auth"
        elif "logEvents" in log:
            return "cloudwatch"
        else:
            return "application"


# Example usage
if __name__ == "__main__":
    import argparse
    
    # Command-line argument parsing
    parser = argparse.ArgumentParser(
        description='Generate AWS raw logs and send to Graylog',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate logs and save to file only
  python script.py
  
  # Send logs to Graylog via UDP
  python script.py --host graylog.example.com --port 12201
  
  # Send logs via TCP with threat intel enabled
  python script.py --host 10.0.1.50 --port 12201 --protocol tcp --threat-intel
  
  # Generate 1000 logs and send to Graylog
  python script.py --host graylog.local --count 1000 --threat-intel
        """
    )
    
    parser.add_argument('--host', type=str, help='Graylog server hostname or IP address')
    parser.add_argument('--port', type=int, default=12201, help='Graylog GELF input port (default: 12201)')
    parser.add_argument('--protocol', type=str, choices=['udp', 'tcp'], default='udp', 
                        help='Protocol to use: udp or tcp (default: udp)')
    parser.add_argument('--count', type=int, default=500, help='Number of logs to generate (default: 500)')
    parser.add_argument('--threat-intel', action='store_true', 
                        help='Enable threat intelligence enrichment (default: disabled)')
    parser.add_argument('--environment', type=str, default='production', 
                        help='Environment name (default: production)')
    parser.add_argument('--region', type=str, default='us-east-1', 
                        help='AWS region (default: us-east-1)')
    parser.add_argument('--output', type=str, default='aws_raw_logs.json',
                        help='Output filename (default: aws_raw_logs.json)')
    
    args = parser.parse_args()
    
    # Initialize generator
    print("=== AWS Raw Log Generator ===\n")
    generator = AWSRawLogGenerator(
        environment=args.environment,
        region=args.region,
        enable_threat_intel=args.threat_intel
    )
    
    print(f"Configuration:")
    print(f"  AWS Account: {generator.aws_account_id}")
    print(f"  VPC: {generator.vpc_id}")
    print(f"  Environment: {args.environment}")
    print(f"  Region: {args.region}")
    print(f"  Threat Intel: {'Enabled' if args.threat_intel else 'Disabled'}")
    print(f"  Log Count: {args.count}\n")
    
    # Generate logs
    print(f"Generating {args.count} logs...")
    logs = generator.generate_log_batch(count=args.count)
    print(f"✓ Generated {len(logs)} logs\n")
    
    # Always save to file
    print(f"Saving logs to file: {args.output}")
    generator.export_to_graylog_format(logs, args.output)
    print()
    
    # Send to Graylog if host is specified
    if args.host:
        print(f"Sending logs to Graylog...")
        generator.send_to_graylog(
            logs=logs,
            graylog_host=args.host,
            graylog_port=args.port,
            protocol=args.protocol
        )
    else:
        print("ℹ No Graylog host specified. Logs saved to file only.")
        print("  To send to Graylog, use: --host <hostname> --port <port>\n")
    
    # Print sample log
    print("\n=== Sample Log ===")
    if logs:
        sample = logs[0]
        print(json.dumps(sample, indent=2, default=str)[:500] + "...")
    
    # Statistics
    print("\n=== Statistics ===")
    log_types = {}
    for log in logs:
        log_type = generator._identify_log_type(log)
        log_types[log_type] = log_types.get(log_type, 0) + 1
    
    print("Log type distribution:")
    for log_type, count in sorted(log_types.items()):
        print(f"  {log_type}: {count}")
    
    if args.threat_intel:
        high_threat = sum(1 for l in logs if isinstance(l, dict) and 
                         l.get("threat_intel", {}).get("threat_score", 0) > 60)
        print(f"\nThreat intelligence:")
        print(f"  High threat score IPs: {high_threat}")
    
    print("\n✓ Complete!")
