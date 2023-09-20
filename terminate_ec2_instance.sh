#!/bin/bash

is_valid_ip() {
  local ip=$1
  if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}


read -p "Enter the private IP address of the EC2 instance: " PRIVATE_IP

if ! is_valid_ip "$PRIVATE_IP"; then
  echo "Invalid IP address format. Please enter a valid private IP address."
  exit 1
fi


INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=private-ip-address,Values=$PRIVATE_IP" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text)

if [ -z "$INSTANCE_ID" ]; then
  echo "No EC2 instance found with the provided private IP address: $PRIVATE_IP"
  exit 1
fi

echo "Found instance with private IP $PRIVATE_IP and ID: $INSTANCE_ID"


read -p "Do you want to terminate this instance? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Termination canceled."
  exit 0
fi


aws ec2 terminate-instances --instance-ids $INSTANCE_ID

aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

echo "Instance $INSTANCE_ID has been terminated."
