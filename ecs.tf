# --- ECS Cluster ---

resource "aws_ecs_cluster" "main" {
  name = "demo-cluster"
}

# --- ECS Capacity Provider ---

resource "aws_ecs_capacity_provider" "main" {
  name = "demo-ecs-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }
}
//Run terraform apply again and after it we should see Capacity Provider & EC2 instances connect to ECS cluster on AWS Console > ECS > demo-cluster > Infrastructure tab.

# --- Cloud Watch Logs ---

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 14
}

# --- ECS Task Definition ---

resource "aws_ecs_task_definition" "app" {
  family             = "demo-app"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name = "app",
    //image        = "${aws_ecr_repository.app.repository_url}:latest",
    image        = "nginxdemos/hello:latest",
    essential    = true,
    portMappings = [{ containerPort = 80, hostPort = 80 }],

    environment = [
      { name = "EXAMPLE", value = "example" }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        //"awslogs-region"        = "us-east-1",
        "awslogs-region"        = "eu-north-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "app"
      }
    },
  }])
}


# --- ECS Service ---

resource "aws_security_group" "ecs_task" {
  name_prefix = "ecs-task-sg-"
  description = "Allow all traffic within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.ecs_task.id]
    subnets         = aws_subnet.public[*].id
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  # --- ECS Service --- connect ecs to alb
  depends_on = [aws_lb_target_group.app]

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 80
  }
}


//The ordered_placement_strategy will try to make sure that each service instance is equally distributed across Availability Zones

resource "aws_ecs_task_definition" "postgres" {
  family             = "demo-postgres"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 512
  memory             = 512

  container_definitions = jsonencode([{
    name         = "postgres",
    image        = "bitnami/postgresql:14",
    essential    = true,
    portMappings = [{ containerPort = 5432, hostPort = 5432 }],

    environment = [
      { name = "POSTGRESQL_PASSWORD", value = "mydb@123" },
      { name = "POSTGRESQL_DATABASE", value = "mydb" },
      { name = "POSTGRESQL_USERNAME", value = "myuser" },
      { name = "POSTGRESQL_POSTGRES_PASSWORD", value = "root@123" }
    ]

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "eu-north-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = "postgres"
      }
    },
  }])
  volume {
    name = "postgres"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs_db.id
      authorization_config {
        access_point_id = aws_efs_access_point.postgres_access_point.id
      }
      transit_encryption = "ENABLED"
    }
  }
}


resource "aws_ecs_service" "postgres" {
  name            = "postgres"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.postgres.arn
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.ecs_task.id]
    subnets         = aws_subnet.public[*].id
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  # --- ECS Service --- connect ecs to alb
  depends_on = [aws_lb_target_group.app]

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "postgres"
    container_port   = 5432
  }
}