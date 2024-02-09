This Terraform configuration sets up an AWS infrastructure with several components including VPC, subnets (public and private), internet gateway, route tables, security groups, load balancer, target groups, autoscaling group, launch template, CloudWatch alarms, etc. This infrastructure is designed to deploy a simple web application with an Application Load Balancer (ALB) distributing traffic to EC2 instances running Apache HTTP servers.

Here's a breakdown of the components:

VPC and Subnets: Defines a VPC with CIDR block 10.0.0.0/16 and three subnets - two public subnets (10.0.1.0/24 and 10.0.2.0/24) and one private subnet (10.0.3.0/24).

Internet Gateway and Route Tables: Associates an internet gateway with the VPC and creates route tables for routing internet traffic to the public subnets.

Security Groups: Defines security groups for the EC2 instances and the ALB, allowing specific inbound and outbound traffic.

Application Load Balancer (ALB): Creates an ALB in the public subnets, distributing incoming HTTP and HTTPS traffic to the target groups.

Target Groups: Specifies target groups for the ALB to route traffic to, and defines health checks for the instances.

Launch Template and Autoscaling Group: Sets up a launch template for EC2 instances with user data to configure Apache HTTP servers. An autoscaling group is created to manage the EC2 instances, ensuring availability and scalability.

CloudWatch Alarms: Creates CloudWatch alarms based on CPU utilization metrics to trigger autoscaling policies for scaling in or out based on resource usage.

Outputs: Provides an output for the ALB DNS name.

User Data Script: Bash script to be executed on EC2 instances when launched, installing and configuring Apache HTTP servers and generating some HTML pages.

Output<b>

![image](https://github.com/ankusheswapnil96/Terraform-Application-Load-Balancer/assets/124359056/8679f475-3ffe-4ffd-a18f-fae574f931a7)

![image](https://github.com/ankusheswapnil96/Terraform-Application-Load-Balancer/assets/124359056/7c3de4af-6757-4a78-b5f7-61fd92196dd6)

