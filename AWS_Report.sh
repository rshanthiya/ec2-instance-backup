touch lab-running-instances.txt
for INSTANCE in $(aws --region us-east-1 ec2 describe-instances --filter Name=instance-state-name,Values=running --output text --query 'Reservations[*].Instances[*].InstanceId') ;\
do 
echo $INSTANCE
INSTANCENAME=$(aws --region us-east-1 ec2 describe-instances --instance-id $INSTANCE --output text --query "Reservations[].Instances[].Tags[?Key=='Name'].Value")
IPADDRESS=$(aws --region us-east-1 ec2 describe-instances --instance-id $INSTANCE --output text --query "Reservations[].Instances[].PrivateIpAddress")
OS=$(aws --region us-east-1 ec2 describe-instances --instance-id $INSTANCE --output text --query "Reservations[].Instances[].Tags[?Key=='Os'].Value")
echo $INSTANCENAME $IPADDRESS $OS >> lab-running-instances.txt ;\
done
cat lab-running-instances.txt
