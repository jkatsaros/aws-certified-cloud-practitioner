$awsec2vpcs = aws ec2 describe-vpcs | ConvertFrom-Json
$awsec2sg = aws ec2 describe-security-groups | ConvertFrom-Json
$awsec2sn = aws ec2 describe-subnets | ConvertFrom-Json
$awsec2 = aws ec2 run-instances --image-id ami-0103f211a154d64a6 --count 1 --instance-type t2.micro --key-name ccp-ec2-keypair --security-group-ids ($awsec2sg.SecurityGroups | where GroupName -eq "ccp-ec2-sg" | select -expand GroupId) --subnet-id $awsec2sn.Subnets[0].SubnetId --user-data file://user-data-base.txt | ConvertFrom-Json
$awsec2ami = aws ec2 create-image --instance-id $awsec2.InstanceId --name ccp-ec2-ami
$awsec2custom = aws ec2 run-instances --image-id $awsec2ami.ImageId --count 1 --instance-type t2.micro --key-name ccp-ec2-keypair --security-group-ids ($awsec2sg.SecurityGroups | where GroupName -eq "ccp-ec2-sg" | select -expand GroupId) --subnet-id $awsec2sn.Subnets[0].SubnetId --user-data file://user-data.txt | ConvertFrom-Json
aws ec2 stop-instances --instance-ids $awsec2.InstanceId