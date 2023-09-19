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

                    def existingKeyPair = sh(script: """
                        #!/bin/bash
                        # Set AWS CLI credentials
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region $awsRegion

                        # Check if the key pair already exists
                        aws ec2 describe-key-pairs --key-names $keyName --region $awsRegion --output text > existing_key_pair.txt
                    """, returnStatus: true)
                    
                    def existingKeyPairName = readFile("existing_key_pair.txt").trim()

                    if (existingKeyPair == 0) {
                       
                        echo "Key pair $keyName already exists."
                    } else {
                    
                        sh(script: """
                            aws ec2 create-key-pair --key-name $keyName --region $awsRegion
                        """)
                        echo "Key pair $keyName created."
                    }

                 
                    def existingSecurityGroup = sh(script: """
                        aws ec2 describe-security-groups --group-names $securityGroupName --region $awsRegion --output text
                    """, returnStatus: true)

                    if (existingSecurityGroup == 0) {
                        // Security group exists
                        echo "Security group $securityGroupName already exists."
                    } else {
                        
                        sh(script: """
                            aws ec2 create-security-group --group-name $securityGroupName --description "my-sg" --region $awsRegion
                            aws ec2 authorize-security-group-ingress --group-name $securityGroupName --protocol tcp --port 22 --cidr 0.0.0.0/0
                            aws ec2 authorize-security-group-ingress --group-name $securityGroupName --protocol tcp --port 80 --cidr 0.0.0.0/0
                        """)
                        echo "Security group $securityGroupName created."
                    }

                    def instanceInfo = sh(script: """
                        aws ec2 run-instances --image-id $amiId --instance-type $instanceType --security-groups $securityGroupName --key-name $keyName
                    """, returnStdout: true).trim()
                    
                    def instanceId = sh(script: """
                        echo '$instanceInfo' | jq -r '.Instances[0].InstanceId'
                    """, returnStdout: true).trim()

                    sh(script: """
                    aws ec2 create-tags --resources $instanceId --tags Key=Name,Value=$instanceName
                    """)  

                  
                    def privateIpAddress = sh(script: """
                        aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text
                    """, returnStdout: true).trim()

                    echo "Private IP Address: $privateIpAddress"

           
                    sh(script: """
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
                                                "Value": "$privateIpAddress"
                                            }
                                        ]
                                    }
                                }
                            ]
                        }'
                    """)

                
                    echo "existingKeyPair: $existingKeyPairName"
                }
            }
        }
    }
}
