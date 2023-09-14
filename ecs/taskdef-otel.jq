{
    "family": env.CONTAINER_NAME,
    "taskRoleArn": env.TASK_ROLE_ARN,
    "executionRoleArn": env.EXECUTION_ROLE_ARN,
    "networkMode": "awsvpc",
    "cpu": env.CPU,
    "memory": env.MEMORY,
    "requiresCompatibilities": ["FARGATE"],
    "runtimePlatform": { "cpuArchitecture": env.CPU_ARCH },
    "containerDefinitions": [
        {
            "cpu": 0,
            "environment": [
                {
                    "name": "CONFIG_S3_PREFIX",
                    "value": env.CONFIG_S3_PREFIX
                },
                {
                    "name": "CONFIG_S3_BUCKET",
                    "value": env.CONFIG_S3_BUCKET
                }
            ],
            "essential": true,
            "image": env.IMAGE_URI,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": env.AWSLOGS_GROUP,
                    "awslogs-region": env.AWSLOGS_REGION,
                    "awslogs-stream-prefix": env.AWSLOGS_STREAM_PREFIX
                },
                "secretOptions": []
            },
            "dependsOn": [
                {
                    "containerName": "aws-otel-collector",
                    "condition": "START"
                }
            ],
            "mountPoints": [],
            "name": env.CONTAINER_NAME,
            "portMappings": [
                {
                    "appProtocol": "HTTP",
                    "containerPort": (env.PORT|tonumber),
                    "hostPort": (env.PORT|tonumber),
                    "protocol": "tcp"
                }
            ],
            "readonlyRootFilesystem": false,
            "secrets": [
                {
                    "name": "DATABASE_URL",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/cogini/foo/dev/app/db/url"
                },
                {
                    "name": "COOKIE",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/cogini/foo/dev/app/erlang_cookie"
                },
                {
                    "name": "SMTP_HOST",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/cogini/foo/dev/app/smtp/host"
                },
                {
                    "name": "SMTP_PORT",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/cogini/foo/dev/app/smtp/port"
                },
                {
                    "name": "SMTP_USER",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/cogini/foo/dev/app/smtp/user"
                },
                {
                    "name": "SMTP_PASS",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/cogini/foo/dev/app/smtp/pass"
                },
                {
                    "name": "SECRET_KEY_BASE",
                    "valueFrom": "arn:aws:ssm:\(env.AWS_REGION):\(env.AWS_ACCOUNT_ID):parameter/cogini/foo/dev/app/endpoint/secret_key_base"
                }
            ],
            "startTimeout": 30,
            "stopTimeout": 30,
            "volumesFrom": []
        },
        {
            "name": "aws-otel-collector",
            "image": "cogini/awscollector:v0.15.0",
            "cpu": 0,
            "memoryReservation": 256,
            "command":["--config=/etc/otel-config.yaml"],
            "portMappings": [
                {
                    "hostPort": 4317,
                    "containerPort": 4317
                },
                {
                    "hostPort": 4318,
                    "containerPort": 4318
                },
                {
                    "hostPort": 8888,
                    "containerPort": 8888
                },
                {
                    "hostPort": 8889,
                    "containerPort": 8889
                },
                {
                    "hostPort": 13133,
                    "containerPort": 13133
                },
                {
                    "hostPort": 2000,
                    "containerPort": 2000,
                    "protocol": "udp"
                }
            ],
            "essential": false,
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": env.AWSLOGS_GROUP,
                    "awslogs-region": env.AWSLOGS_REGION,
                    "awslogs-stream-prefix": env.AWSLOGS_STREAM_PREFIX
                },
                "secretOptions": []
            },
            "startTimeout": 30,
            "stopTimeout": 30,
            "volumesFrom": []
        }
    ]
}
