$awsec2vpcs = aws ec2 describe-vpcs | ConvertFrom-Json
$awsec2sg = aws ec2 describe-security-groups | ConvertFrom-Json
$awsec2sn = aws ec2 describe-subnets | ConvertFrom-Json
$awsec21 = aws ec2 run-instances --image-id ami-0103f211a154d64a6 --count 1 --instance-type t2.micro --key-name ccp-ec2-keypair --security-group-ids ($awsec2sg.SecurityGroups | where GroupName -eq "ccp-ec2-sg" | select -expand GroupId) --subnet-id $awsec2sn.Subnets[0].SubnetId --user-data file://user-data-base.txt | ConvertFrom-Json
$awsec22 = aws ec2 run-instances --image-id ami-0103f211a154d64a6 --count 1 --instance-type t2.micro --key-name ccp-ec2-keypair --security-group-ids ($awsec2sg.SecurityGroups | where GroupName -eq "ccp-ec2-sg" | select -expand GroupId) --subnet-id $awsec2sn.Subnets[0].SubnetId --user-data file://user-data-base.txt | ConvertFrom-Json
$awsec2alb = aws elbv2 create-load-balancer --name ccp-ec2-alb --subnets $awsec2sn.Subnets[0].SubnetId $awsec2sn.Subnets[1].SubnetId --security-groups ($awsec2sg.SecurityGroups | where GroupName -eq "ccp-ec2-sg" | select -expand GroupId) | ConvertFrom-Json
$awsec2lbtg = aws elbv2 create-target-group --name ccp-ec2-lb-tg --protocol HTTP --port 80 --vpc-id $awsec2vpcs.Vpcs[0].VpcId --ip-address-type ipv4 | ConvertFrom-Json
aws elbv2 register-targets --target-group-arn $awsec2lbtg.TargetGroups[0].TargetGroupArn --targets Id=$awsec21.InstanceId Id=$awsec22.InstanceId
aws elbv2 create-listener --load-balancer-arn $awsec2alb.LoadBalancers[0].LoadBalancerArn --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$awsec2lbtg.TargetGroups[0].TargetGroupArn
aws elbv2 describe-target-health --target-group-arn $awsec2lbtg.TargetGroups[0].TargetGroupArn
aws ec2 stop-instances --instance-ids $awsec2.InstanceId