#!/bin/bash -ex
aws s3 ls
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo $TIMESTAMP
SLUG=$(echo $DESCRIPTION | tr [:upper:] [:lower:] | tr -s ' ' | tr ' ' '-' )
# ID of the EC2 instance
Instanceid=$(aws ec2 describe-instances --region us-east-1 --output text --query 'Reservations[*].Instances[*].InstanceId')
echo $Instanceid
# EC2 instance state
#STATE=$(aws ec2 describe-instances --region us-east-1 --filters Name=instance-state-name,Values=stopped --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output text)
#STATE=$(aws ec2 describe-instances --region us-east-1 --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output text)
STATE=$(aws ec2 describe-instances --instance-ids $Instanceid --region $REGION --query 'Reservations[].Instances[].State.Name' --output text)
# EC2 instance exist or not
if [ -z "$Instanceid" ]; then
    echo "Error: INSTANCEID is not set or is empty."
    exit 1
else
    echo "INSTANCEID is set to $Instanceid"
    # Proceed with AWS CLI commands
    aws ec2 describe-instances --region us-east-1 --instance-ids "$Instanceid"
fi
# If user selected shutdown the instances then stop the instance
if [ $SHUTDOWN == "yes" ]; then
aws ec2 stop-instances --instance-ids $Instanceid --region $REGION
aws ec2 wait instance-stopped --instance-ids $Instanceid --region $REGION
fi
# EC2 instance snapshot for all attched volumes
aws ec2 create-snapshots --instance-specification InstanceId=$Instanceid --region $REGION --copy-tags-from-source volume --description "$SLUG-$TIMESTAMP"
# Restart the instance if its stopped state
if [ $STATE == "stopped" ]; then
aws ec2 start-instances --instance-ids $Instanceid --region $REGION
fi
