# create Terraform code for impelemnting an ECS cluster with EC2 capacity provider

This article will look at how to create a Terraform configuration to provide such resources:

## VPC with public subnet
1 Internet Gateway to connect to the global Internet
2 Security groups for EC2 Node & ECS Service
3 Auto-scaling group for ECS cluster with Launch Templates
4 Publish image to ECR
5 ECS cluster with task and service definition
6 Load Balancer to public access & scale ECS Service

## the steps are:
1 create vpc
2 Creating a scalable ECS Cluster
3 IAM Role & Security Group for ECS EC2 Node
4 Launch Template
5 Autoscaling Group
6 Capacity Provider
7 Creating ECS Service
    1 Create Elastic Container Registry (ECR) & push image
    2 Create IAM Role for ECS Task
    3 Create ECS Task Definition
    4 Create Security Group for service
    5 Create ECS Service
    6 Create Load Balancer
8 Connect ECS Service to ALB
curl $(terraform output --raw alb_url) # Hello from ip-10-10-10-XXX

9 Bonus: ECS Service Auto Scaling
 ECS Service Auto Scaling
```
resource "aws_appautoscaling_target" "ecs_target" {
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.app.name}"
  min_capacity       = 2
  max_capacity       = 5
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "ecs_target_memory" {
  name               = "application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 80
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
```
soruce: https://medium.com/@vladkens/aws-ecs-cluster-on-ec2-with-terraform-2023-fdb9f6b7db07
