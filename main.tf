provider "aws" {
    region = "us-east-1"
  
}

resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "publicsubnet1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true  
    availability_zone = data.aws_availability_zones.azs.names[0]    #us-east-1-a
}

resource "aws_subnet" "publicsubnet2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true      
    availability_zone = data.aws_availability_zones.azs.names[1]    #us-east-1-b
}

resource "aws_subnet" "privatesubnet1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.3.0/24"    
    availability_zone = data.aws_availability_zones.azs.names[3]    #us-east-1-c
}

resource "aws_internet_gateway" "myigw" {
    vpc_id = aws_vpc.myvpc.id    
    tags = {
        Name = "myIGW"
    }
}

resource "aws_route_table" "myrt1" {
    vpc_id = aws_vpc.myvpc.id
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myigw.id
    }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.myrt1.id
}

resource "aws_route_table_association" "b" {
  subnet_id = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.myrt1.id
}
resource "aws_default_security_group" "mysg" {        
    vpc_id = aws_vpc.myvpc.id
    
    ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
}

resource "aws_security_group" "lb" {
    name = "albSecurityGroup"
    description = "Security group for application load balancer"
    vpc_id = aws_vpc.myvpc.id
    ingress {
        description = "HTTP"
        to_port = 80
        from_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
    ingress {
        description = "HTTPS"
        to_port = 443
        from_port = 443
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    # Allow all outbound traffic.
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
  
}

resource "aws_lb_target_group" "target1" {
    name = "TG1"
    target_type = "instance"
    protocol = "HTTP"
    port = 80
    vpc_id = aws_vpc.myvpc.id
    
    stickiness {
        enabled = true
        type = "lb_cookie"
        cookie_duration = 2
    }

    health_check {
      enabled = true
      healthy_threshold = 3
      unhealthy_threshold = 2
      timeout = 5
      interval = 30
      matcher = 200
      path = "/index.html"
    }
}

resource "aws_lb_target_group" "target2" {
    name = "TG2"
    target_type = "instance"
    protocol = "HTTP"
    port = 80
    vpc_id = aws_vpc.myvpc.id
    
    stickiness {
        enabled = true
        type = "lb_cookie"
        cookie_duration = 2
    }

    health_check {
      enabled = true
      healthy_threshold = 3
      unhealthy_threshold = 2
      timeout = 5
      interval = 30
      matcher = 200
      path = "/index.html"
    }
}


resource "aws_lb" "myalb" {
    name = "myALB"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.lb.id ]
    subnets = [ aws_subnet.publicsubnet1.id, aws_subnet.publicsubnet2.id ]
    enable_deletion_protection = false

    tags = {
        name = "My AWS ALB Load Balancer"
    }

#    access_logs {
#   bucket  = aws_s3_bucket.lb_logs.id
#    prefix  = "alb-logs"
#    enabled = true
#  }


}

resource "aws_lb_listener" "http" {

    load_balancer_arn = aws_lb.myalb.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"

      forward {
        target_group {
          arn = aws_lb_target_group.target1.arn
          
        }

        target_group {
          
          arn = aws_lb_target_group.target2.arn
        }
        
        stickiness {
        enabled  = true
        duration = 2
      }

      }
    }

}

resource "aws_lb_listener_rule" "rule1" {
    listener_arn = aws_lb_listener.http.arn
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.target1.arn
    }

    condition {
      path_pattern {
        values = [ "/server1/*" ]
      }
    }
  
}

resource "aws_lb_listener_rule" "rule2" {
  listener_arn = aws_lb_listener.http.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target2.arn
  }

  condition {
    path_pattern {
      values = [ "/server2/*" ]
    }
  }

}

resource "aws_launch_template" "launchTemplate-amazonlinux" {
    name = "autoscalingTier3Template"
    description = "Launch template for autoscaling Tier 3 Infra"
    image_id = data.aws_ami.amazon-linux.id
    instance_type = "t2.micro"
    key_name = "MyKey"

    vpc_security_group_ids = [aws_default_security_group.mysg.id]
    update_default_version = true
    user_data = filebase64("${path.module}/indexscript.sh")
}

resource "aws_autoscaling_group" "myasg" {
    name_prefix = "myasg-"
    launch_template {
    id      = aws_launch_template.launchTemplate-amazonlinux.id
    version = "$Latest"
    }
    vpc_zone_identifier = [ aws_subnet.publicsubnet1.id, aws_subnet.publicsubnet2.id]

    desired_capacity = 2
    min_size = 2
    max_size = 4

    health_check_grace_period = 300
    health_check_type = "ELB"    
    target_group_arns = [ aws_lb_target_group.target1.arn, aws_lb_target_group.target2.arn ]
  
}


resource "aws_autoscaling_policy" "scale_out" {
    name = "scale_out"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.myasg.name
  
}

resource "aws_cloudwatch_metric_alarm" "cpuUtilizationIncreased" {
  alarm_name = "cpuUtilizationIncreased"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold = 70
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  alarm_description = "Generate alarm if cpu utilization above 70%"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.myasg.name}"
  }
  alarm_actions = [ "${aws_autoscaling_policy.scale_out.arn}" ]
}


resource "aws_autoscaling_policy" "scale_in" {
    name = "scale_in"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = aws_autoscaling_group.myasg.name
  
}

resource "aws_cloudwatch_metric_alarm" "cpuUtilizationDecreased" {
  alarm_name = "cpuUtilizationDecreased"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold = 30
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 120
  statistic = "Average"
  alarm_description = "Generate alarm if cpu utilization below 50%"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.myasg.name}"
  }
  alarm_actions = [ "${aws_autoscaling_policy.scale_in.arn}" ]
}
