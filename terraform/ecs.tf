resource "aws_ecr_repository" "fe_main" {
  name                 = "${var.name}-${var.env}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "fe_main" {
  repository = aws_ecr_repository.fe_main.name
 
  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 10 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 10
     }
   }]
  })
}


resource "aws_ecr_repository" "be_main" {
  name                 = "${var.name}-${var.env}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete = false
}

resource "aws_ecr_lifecycle_policy" "be_main" {
  repository = aws_ecr_repository.be_main.name
 
  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 10 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 10
     }
   }]
  })
}


resource "aws_ecs_cluster" "TF_main" {
  name = "${var.name}-cluster-${var.env}"
}

resource "aws_cloudwatch_log_group" "frontend" {
  name = "frontend-logs"

  tags = {
    Environment = var.env
    Application = "Vitfor"
    Tier = "frontend"
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name = "backend-logs"

  tags = {
    Environment = var.env
    Application = "Vitfor"
    Tier = "backend"
  }
}

# Frontend task
resource "aws_ecs_task_definition" "TF_frontend_task_def" {
  family = "frontend-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2","FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  # container_definitions = file("task-definitions/frontend.json")

  container_definitions = jsonencode([
        {
          "portMappings" = [
            {
              "hostPort" = 3000,
              "protocol" = "tcp",
              "containerPort" = 3000
            }
          ],
          "logConfiguration" = {
            "logDriver" = "awslogs",
            "secretOptions" = null,
              "options" = {
                "awslogs-group" = "${aws_cloudwatch_log_group.frontend.id}",
                "awslogs-region" = "${var.region}",
                "awslogs-stream-prefix" = "ecs"
              }
        },
          "cpu" = 0,
          "image" = "${var.account}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.fe_main.name}:frontend",
          "essential" = true,
          "name" = "frontend"
        },

        {
          "cpu" = 0,
          "image" = "${var.account}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.fe_main.name}:nginx",
          "essential" = true,
          "name" = "nginx",
          "portMappings" = [ 
            {
              "hostPort" = 80,
              "protocol" = "tcp",
              "containerPort" = 80
            }
          ],
          "logConfiguration" = {
            "logDriver" = "awslogs",
            "secretOptions" = null,
              "options" = {
                "awslogs-group" = "${aws_cloudwatch_log_group.frontend.id}",
                "awslogs-region" = "${var.region}",
                "awslogs-stream-prefix" = "ecs"
              }
        }
        }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
  }

}

# Backend task
resource "aws_ecs_task_definition" "TF_backend_task_def" {
  family = "backend-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  # container_definitions = file("task-definitions/backend.json")


  container_definitions = jsonencode([

        {
          "name" = "nginx",
          "image" = "${var.account}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.be_main.name}:nginx",
          # "memory" = 100,
          # "cpu" = 99,
          "portMappings" = [
            {
              "hostPort" = 80,
              "protocol" = "tcp",
              "containerPort" = 80
            }
          ],
          "logConfiguration" = {
            "logDriver" = "awslogs",
            "secretOptions" = null,
              "options" = {
                "awslogs-group" = "${aws_cloudwatch_log_group.backend.id}",
                "awslogs-region" = "${var.region}",
                "awslogs-stream-prefix" = "ecs"
              }
        },
          "secrets" = [
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/API_HOST",
              "name" = "API_HOST"
            }
          ],
          
          "dependsOn" = [
            {
              "containerName" = "web",
              "condition" = "HEALTHY"
            }
          ],
          "essential" = true,
          "readonlyRootFilesystem" = false
        },
        {
          "name" = "web",
          "image" = "${var.account}.dkr.ecr.${var.region}.amazonaws.com/${aws_ecr_repository.be_main.name}:web",
          # "memory" = 100,
          # "cpu" = 99,
          "command" = [
            "exec gunicorn auth_system.wsgi:application --bind 0.0.0.0:8000"
          ],
          "logConfiguration" = {
            "logDriver" = "awslogs",
            "secretOptions" = null,
              "options" = {
                "awslogs-group" = "${aws_cloudwatch_log_group.backend.id}",
                "awslogs-region" = "${var.region}",
                "awslogs-stream-prefix" = "ecs"
              }
        },
          "environment" = [
            {
              "name" = "DEBUG",
              "value" = "1"
            }
          ],
          "secrets" = [
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/DJANGO_ALLOWED_HOSTS",
              "name" = "DJANGO_ALLOWED_HOSTS"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/DJANGO_SUPERUSER_EMAIL",
              "name" = "DJANGO_SUPERUSER_EMAIL"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/DJANGO_SUPERUSER_EMAIL",
              "name" = "DJANGO_SUPERUSER_EMAIL_2"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/DJANGO_SUPERUSER_PASSWORD",
              "name" = "DJANGO_SUPERUSER_PASSWORD"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/terraform/DOMAIN",
              "name" = "DOMAIN"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/SQL_DATABASE",
              "name" = "POSTGRES_DATABASE"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/POSTGRES_DB",
              "name" = "POSTGRES_DB"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/terraform/POSTGRES_HOST",
              "name" = "POSTGRES_HOST"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/SQL_PASSWORD",
              "name" = "POSTGRES_PASSWORD"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/SQL_PORT",
              "name" = "POSTGRES_PORT"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/SQL_USER",
              "name" = "POSTGRES_USER"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/SECRET_KEY",
              "name" = "SECRET_KEY"
            },
            {
              "valueFrom" = "arn:aws:ssm:${var.region}:${var.account}:parameter/vitfor/prod/SQL_ENGINE",
              "name" = "SQL_ENGINE"
            }
          ],

          "healthCheck" = {
            "retries" = 4,
            "command" = [
              "CMD-SHELL",
              "curl -v --insecure --anyauth --user username:password -H \"Accept = application/json\" -H \"Content-Type = application/json\" -X GET localhost:8000/api/health/ || exit 1"
            ],
            "timeout" = 10,
            "interval" = 30,
            "startPeriod" = 10
          },
          "essential" = true
    } 

  ])


  runtime_platform {
    operating_system_family = "LINUX"
  }

}

##########
# Services
##########


resource "aws_ecs_service" "frontend_service" {
 name                               = "${var.name}-frontend-service-${var.env}"
 cluster                            = aws_ecs_cluster.TF_main.id
 task_definition                    = aws_ecs_task_definition.TF_frontend_task_def.arn
 desired_count                      = 1
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent         = 100
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"
 health_check_grace_period_seconds = 300

 
 network_configuration {
   security_groups  = [aws_security_group.frontend_task_sg.id]
   subnets = [aws_subnet.public[element(keys(aws_subnet.public), 0)].id] # changed to private
   assign_public_ip = true
 }
 
 load_balancer {
   target_group_arn = aws_alb_target_group.public_tg.id
   container_name   = "nginx"
   container_port   = 80
 }

  # service_registries {
  #   registry_arn = "${aws_service_discovery_service.frontend.arn}" # WORKING ON THIS
  #   container_name = "nginx"
  #   container_port = "80"
  # }
 
#  lifecycle {
  #  ignore_changes = [task_definition, desired_count]
#  }
}

resource "aws_ecs_service" "backend_service" {
 name                               = "${var.name}-backend-service-${var.env}"
 cluster                            = aws_ecs_cluster.TF_main.id
 task_definition                    = aws_ecs_task_definition.TF_backend_task_def.arn
 desired_count                      = 1
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent         = 200
#  health_check_grace_period_seconds = 300
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"
 
  network_configuration {
    security_groups  = [aws_security_group.backend_task_sg.id]
    subnets = [aws_subnet.private[element(keys(aws_subnet.private), 0)].id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.private_tg.id
    container_name   = "nginx"
    container_port   = 80
  }

  # service_registries {
  #   registry_arn = "${aws_service_discovery_service.backend.arn}" # WORKING ON THIS
  #   container_name = "nginx"
  #   container_port = "443"
  # }


 
  # lifecycle {
  #   ignore_changes = [task_definition, desired_count]
  # }
}

resource "aws_ssm_parameter" "django_domain" {
  name  = "/vitfor/prod/terraform/DOMAIN"
  type  = "String"
  value = var.domain
}