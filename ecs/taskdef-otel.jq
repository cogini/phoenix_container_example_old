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
                    "appProtocol": "http",
                    "containerPort": (env.PORT|tonumber),
                    "hostPort": (env.PORT|tonumber),
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
            "image": "public.ecr.aws/aws-observability/aws-otel-collector",
            "cpu": 0,
            "memoryReservation": 256,
            "command":["--config=/etc/ecs/ecs-default-config.yaml"],
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
                    "awslogs-group": env.AWSLOGS_GROUP,
                    "awslogs-region": env.AWSLOGS_REGION,
                    "awslogs-stream-prefix": "foo-app"
                },
                "secretOptions": []
            },
            "startTimeout": 30,
            "stopTimeout": 30,
            "volumesFrom": []
        }
    ]
}
