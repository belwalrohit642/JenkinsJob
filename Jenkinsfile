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
                    
                    def bashScript = """
                       #!/bin/bash
                        # Set AWS CLI credentials (ensure these are properly configured in Jenkins)
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws configure set region us-east-1  

keyName="MyKeyPair"
securityGroupName="MySecurityGroup"
instanceName="MyInstance"
amiId="ami-053b0d53c279acc90"
instanceType="t2.micro" 
recordName="test.rahul.com"
hostedZoneId="Z04318891OPKK2SEM5DXF"
awsRegion="us-east-1"



aws ec2 create-key-pair --key-name "$keyName" --region "$awsRegion"
aws ec2 create-security-group --group-name "$securityGroupName"  --description "my-sg" --region "$awsRegion"


aws ec2 authorize-security-group-ingress --group-name "$securityGroupName" --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-name "$securityGroupName" --protocol tcp --port 80 --cidr 0.0.0.0/0

instanceInfo=$(aws ec2 run-instances --image-id "$amiId" --instance-type "$instanceType" --security-groups "$securityGroupName" --key-name "$keyName")

instanceId=$(echo "$instanceInfo" | jq -r '.Instances[0].InstanceId')

aws ec2 create-tags --resources "$instanceId" --tags Key=Name,Value="$instanceName"


privateIpAddress=$(aws ec2 describe-instances --instance-ids "$instanceId" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

echo "Private IP Address: $privateIpAddress"

aws route53 change-resource-record-sets --hosted-zone-id "$hostedZoneId" --change-batch '{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'"$recordName"'",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "'"$privateIpAddress"'"
          }
        ]
      }
    }
  ]
}'


                    """
                    
                    sh(script: bashScript, returnStatus: true)
                }
            }
        }

    }

    
}
