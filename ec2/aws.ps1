aws ec2 create-key-pair --key-name ccp-ec2-keypair --key-type rsa --key-format pem --query "KeyMaterial" --output text > ccp-ec2-keypair.pem
$awsec2vpcs = aws ec2 describe-vpcs | ConvertFrom-Json
$awsec2sg = aws ec2 create-security-group --group-name ccp-ec2-sg --description "Certified Cloud Practitioner EC2 Security Group" --vpc-id $awsec2vpcs.Vpcs.VpcId | ConvertFrom-Json
aws ec2 authorize-security-group-ingress --group-id $awsec2sg.GroupId --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $awsec2sg.GroupId --protocol tcp --port 80 --cidr 0.0.0.0/0
$awsec2sn = aws ec2 describe-subnets | ConvertFrom-Json
$awsec2 = aws ec2 run-instances --image-id ami-0103f211a154d64a6 --count 1 --instance-type t2.micro --key-name ccp-ec2-keypair --security-group-ids $awsec2sg.GroupId --subnet-id $awsec2sn.Subnets[0].SubnetId | ConvertFrom-Json
aws ec2 stop-instances --instance-ids $awsec2.InstanceId