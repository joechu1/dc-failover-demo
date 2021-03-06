# Fault Tolerant Applications with Apache Cassandra™ Demo

Demo project to provision and deploy a multi-tier application architecture that is resilient to infrastructure outages
at Availability Zone and Region level using Cassandra.

## Table of contents

- [Description](#description)
- [Architecture diagram](#architecture-diagram)
- [Schema and Queries](#schema-and-queries)
- [Requirements](#requirements)
- [Provisioning](#provisioning)
- [Load testing](#load-testing)
- [Simulate outages](#simulate-outages)

## Description

This project contains the support files to provision the instances and services on AWS, along with instructions to
simulate Availability Zone and Region level outages. You will be able to deploy a sample application on a cloud 
provider and see how it behaves during those outages, while handling incoming load to the system.

The following services are created as part of this demo:

- 6 EC2 instances for Cassandra nodes segregated in two data-centers:
    - Region us-east-1: 3 EC2 `m5.2xlarge` instances across 3 Availability Zones (AZ). 
    - Region us-west-2: 3 EC2 `m5.2xlarge` instances across 3 AZs.
- 6 EC2 `m5.large` instances to be used for application services, one in each AZ.
- 2 [Elastic Load Balancers (ELB)][elb], one per region, with health checks enabled.
- 1 [AWS Global Accelerator][gacc] as ELBs anycast frontend, with health checks enabled.
- 2 EC2 `t2.small` instances to be used as clients, one in each region. 

Note that regions used in this demo can be configured if needed.

Equivalent solutions can be deployed in other public cloud providers and on premise, please refer to the whitepaper 
for more information.

## Architecture diagram

![Architecture diagram](https://i.imgur.com/N2OKUZ2.png)

_Note that each web instance connects to all the Cassandra nodes within the region, regardless of the AZ._

## Schema and Queries
### Schema
```
CREATE KEYSPACE IF NOT EXISTS shopping WITH REPLICATION = {'class':'NetworkTopologyStrategy','us-east-1': 3,'us-west-2': 3};
CREATE TABLE IF NOT EXISTS shopping.carts (
	username text,
	item_id int,
	date_added timestamp,
	item_name text,
	PRIMARY KEY (username, item_id, date_added))
```
### Queries
Reads: Consistency Level = LOCAL_QUORUM
```
SELECT * FROM shopping.carts WHERE username = ?
```
Writes: Consistency Level = LOCAL_QUORUM
```
INSERT INTO shopping.carts (username, item_id, date_added, item_name) VALUES (?, ?, toTimestamp(now()), ?)
```

This demo uses OSS Java Driver 4.x

## Requirements

- [Packer][packer] v1.2 or above.
- [Terraform][terraform] v0.12 or above.
- AWS Account.

## Provisioning

Infrastructure is created and provisioned using [Terraform][terraform] and software for Apache Cassandra, microservices 
and client load testing tool is deployed using [Packer][packer] images.

Note that images, instances and services created on AWS have an associated cost. Estimated cost of running this demo 
on AWS is around $10 per hour.

### Clone the repository

```bash
git clone git@github.com:datastax/dc-failover-demo.git
cd dc-failover-demo
```

### Packer images

To build the images on the different regions use:

```bash
packer build ./packer/template.json
```

Expect building the images to take several minutes.

### Terraform

To create the instances and services use:

```bash
terraform apply ./terraform/
```

### Verify

Terraform exports output values that are displayed after creating the infrastructure and provisioning.

These outputs are AWS Global Accelerator public IP addresses, load tester clients public IPs, bastion public IP and
dev private key to access the bastion.

Use one of the public ips of the Global Accelerator to access the service:

```bash
curl -i http://<accelerator_public_ip>/
```

### Using Packer and Terraform with AWS Vault / AWS Okta

If you have multiple AWS profiles, we recommend using a tool to manage those credentials, like
[AWS Vault][aws-vault], [AWS Okta][aws-okta]
(if you are using federated login with [Okta][okta]).

To create and deploy the infrastructure with AWS Vault, use:

```bash
aws-vault exec <profile_name> -- packer build ./packer/template.json
aws-vault exec <profile_name> -- terraform apply ./terraform/
```

With AWS Okta, use:

```bash
aws-okta exec <profile_name> -- packer build ./packer/template.json
aws-okta exec <profile_name> -- terraform apply ./terraform/
```

## Load testing

This demo uses [Locust][locust] to put demand on the system and measuring its response.

Access the two locust instances using a browser with the urls included in the terraform output, for
example: `http://V.X.Y.Z:8089`.

## Simulate outages

While load testing is ongoing, you can simulate outages at different failure domains to see how the application will
respond to those events.

### Simulate AZ outage

To simulate an Availability Zone outage, we remove the security group rule that allows internal TCP connections on 
Availability Zone 3 at Region 2.  

```bash
terraform destroy \
    -target aws_instance.i_cassandra_r2_i3 \
    -target aws_security_group_rule.sg_rule_sg_r2_az3_allow_all_internal ./terraform/
```

As a result, for new incoming requests the load balancer will route traffic to service instances in the
healthy zones. Application service instances using Apache Cassandra nodes from AZs that were not impacted will not 
experience errors derived from the loss of connectivity to the failed nodes and the drivers will attempt to
reconnect in the background while using the set of live nodes as coordinators for the queries while the failed nodes
are offline.

### Simulate Region outage

To simulate a region-level outage, we remove the security group rules for the whole Region 2 and inter
region VPC peering.

```bash
terraform destroy \
    -target aws_security_group_rule.sg_rule_elb_r2_allow_http \
    -target aws_security_group_rule.sg_rule_default_r2_allow_all_internal \
    -target aws_security_group_rule.sg_rule_sg_r2_az3_allow_all_internal \
    -target aws_vpc_peering_connection.r1_to_r2_requester \
    ./terraform/
```

As a result, for new incoming requests AWS Global Accelerator will route traffic to the ELB instance in the second 
region. Application services that are healthy can continue querying the database targeting the local data center.

Note that Global Accelerator will take ten seconds to identify a target as unhealthy.

### Cleanup

You can cleanup all terraform managed resources with:

```bash
terraform destroy ./terraform/
```

## Notice

The source code contained in this project is designed for demonstration purposes and it's not intended for production
use. A bastion instance is created along with a private key to access using ssh, in case you want to
verify the state of the instances manually. Note that this private key is included in terraform outputs
and can be a security risk in your deployment, outside this demo use keys generated beforehand and store them
securily.

The software is provided "as is", without warranty of any kind.  Any use by you of the source 
code is at your own risk.

[aws-vault]: https://github.com/99designs/aws-vault
[aws-okta]: https://github.com/segmentio/aws-okta
[okta]: https://www.okta.com/
[packer]: https://www.packer.io/
[terraform]: https://www.terraform.io/
[elb]: https://aws.amazon.com/elasticloadbalancing/
[gacc]: https://aws.amazon.com/global-accelerator/
[locust]: https://www.locust.io/
