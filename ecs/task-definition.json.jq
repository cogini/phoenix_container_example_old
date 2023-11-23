{
    "family": "foo-app",
    "taskRoleArn": env.TASK_ROLE_ARN,
    "executionRoleArn": env.EXECUTION_ROLE_ARN,
    "networkMode": "awsvpc",
    "cpu": "256",
    "memory": "512",
    "requiresCompatibilities": ["FARGATE"],
    "runtimePlatform": {"cpuArchitecture": "X86_64"},
    "containerDefinitions": [
        {
            "cpu": 0,
            "dependsOn": [
                {
                    "containerName": "aws-otel-collector",
                    "condition": "START"
                }
            ],
            "environment": [
                {
                    "name": "GITHUB_SHA",
                    "value": env.GITHUB_SHA
                },
                {
                    "name": "GITHUB_HEAD_REF",
                    "value": env.GITHUB_HEAD_REF
                },
                {
                    "name": "PHX_HOST",
                    "value": env.HOST
                },
                {
                    "name": "CONFIG_S3_PREFIX",
                    "value": "app-ecs"
                },
                {
                    "name": "CONFIG_S3_BUCKET",
                    "value": "cogini-foo-dev-app-config"
                },
                {
                    "name": "OTEL_EXPORTER_OTLP_ENDPOINT",
                    "value": "http://localhost:4317"
                },
                {
                    "name": "OTEL_EXPORTER_OTLP_PROTOCOL",
                    "value": "grpc"
                },
                {
                    "name": "OTEL_SERVICE_NAME",
                    "value": "foo-app"
                }
            ],
            "essential": true,
            "image": "<IMAGE1_NAME>",
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/foo-app",
                    "awslogs-region": env.AWSLOGS_REGION,
                    "awslogs-stream-prefix": "foo-app"
                }
            },
            "mountPoints": [],
            "name": "foo-app",
            "portMappings": [
                {
                    "appProtocol": "http",
                    "containerPort": 4000,
                    "hostPort": 4000
                }
            ],
            "readonlyRootFilesystem": false,
            "entryPoint": ["bin/start-docker"],
            "secrets": [
                {
                    "name": "COOKIE",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/\(env.AWS_PS_PREFIX)/app/erlang_cookie"
                },
                {
                    "name": "DATABASE_URL",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/\(env.AWS_PS_PREFIX)/app/db/url"
                },
                {
                    "name": "SECRET_KEY_BASE",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/\(env.AWS_PS_PREFIX)/app/endpoint/secret_key_base"
                },
                {
                    "name": "SMTP_HOST",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/\(env.AWS_PS_PREFIX)/app/smtp/host"
                },
                {
                    "name": "SMTP_PORT",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/\(env.AWS_PS_PREFIX)/app/smtp/port"
                },
                {
                    "name": "SMTP_USER",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/\(env.AWS_PS_PREFIX)/app/smtp/user"
                },
                {
                    "name": "SMTP_PASS",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/\(env.AWS_PS_PREFIX)/app/smtp/pass"
                }
            ],
            "startTimeout": 30,
            "stopTimeout": 30
        },
        {
            "name": "aws-otel-collector",
            "image": "\(env.ECR_REGISTRY)/\(env.ECR_IMAGE_OWNER)aws-otel-collector",
            "cpu": 0,
            "environment": [
                {
                    "name": "AWS_REGION",
                    "value": env.AWSLOGS_REGION
                }
            ],
            "essential": true,
            "healthCheck": {
                "command": [ "/healthcheck" ],
                "interval": 5,
                "timeout": 6,
                "retries": 5,
                "startPeriod": 1
            },
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/ecs-aws-otel-sidecar-collector",
                    "awslogs-region": env.AWSLOGS_REGION,
                    "awslogs-stream-prefix": "foo-app"
                }
            }
        }
    ]
}
