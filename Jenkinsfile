pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Run Bash Script') {
            steps {
                script {
                    def amiId = "ami-053b0d53c279acc90"
                    def instanceType = "t2.micro"
                    def keyName = "MyKeyPair"
                    def securityGroupName = "MySecurityGroup"
                    def instanceName = "MyInstance"
                    def recordName = "test.rahul.com"
                    def hostedZoneId = "Z04318891OPKK2SEM5DXF"
                    def awsRegion = "us-east-1"

                    sh """
                        #!/bin/bash
                        # Set AWS CLI credentials
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $awsRegion

                        # Check if the key pair already exists
                       existingKeyPair=\$(aws ec2 describe-key-pairs --key-names MyKeyPair --region us-east-1 --query 'KeyPairs[0].KeyName' --output text)


                        if [ "$existingKeyPair" = "MyKeyPair" ]; then
                          echo "Key pair MyKeyPair already exists."
                        else  
                          aws ec2 create-key-pair --key-name MyKeyPair --region us-east-1
                        fi

                        aws ec2 create-security-group --group-name $securityGroupName --description "my-sg" --region $awsRegion

                        aws ec2 authorize-security-group-ingress --group-name $securityGroupName --protocol tcp --port 22 --cidr 0.0.0.0/0
                        aws ec2 authorize-security-group-ingress --group-name $securityGroupName --protocol tcp --port 80 --cidr 0.0.0.0/0

                        instanceInfo=\$(aws ec2 run-instances --image-id $amiId --instance-type $instanceType --security-groups $securityGroupName --key-name $keyName)

                        instanceId=\$(echo \$instanceInfo | jq -r '.Instances[0].InstanceId')

                        aws ec2 create-tags --resources \$instanceId --tags Key=Name,Value=$instanceName

                        privateIpAddress=\$(aws ec2 describe-instances --instance-ids \$instanceId --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

                        echo "Private IP Address: \$privateIpAddress"

                        aws route53 change-resource-record-sets --hosted-zone-id $hostedZoneId --change-batch '{
                          "Changes": [
                            {
                              "Action": "UPSERT",
                              "ResourceRecordSet": {
                                "Name": "$recordName",
                                "Type": "A",
                                "TTL": 300,
                                "ResourceRecords": [
                                  {
                                    "Value": "\$privateIpAddress"
                                  }
                                ]
                              }
                            }
                          ]
                        }'
                    """
                }
            }
        }
    }
}
