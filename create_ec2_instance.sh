#!/bin/bash


keyName="MyKeyPair"
securityGroupName="MySecurityGroup"
instanceName="MyInstance"
amiId="ami-053b0d53c279acc90"
instanceType="t2.micro" 
recordName="test.rahul.com"
hostedZoneId="Z04318891OPKK2SEM5DXF"
awsRegion="us-east-1"

aws configure

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

