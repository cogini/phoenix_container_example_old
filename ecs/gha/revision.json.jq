{
    "revisionType": "AppSpecContent",
    "appSpecContent": {
        "content": {
            "version":"0.0",
            "Resources":[
                {
                    "TargetService": {
                        "Type": "AWS::ECS::Service",
                        "Properties": {
                            "TaskDefinition": env.TASKDEF_APP_ARN,
                            "LoadBalancerInfo": {
                                "ContainerName": env.CONTAINER_NAME,
                                "ContainerPort": env.PORT
                            }
                        }
                    }
                }
            ]
        }
    }
}
