#!/bin/bash
date=`date`
echo "#########################################"
echo "Script start $date"
echo "#########################################"

NODE=`oc get nodes --selector=node-role.kubernetes.io/worker -o jsonpath='{.items[0].metadata.name}'`
VPC=`aws ec2 describe-instances --filters "Name=private-dns-name,Values=$NODE" \ 
  --query 'Reservations[*].Instances[*].{VpcId:VpcId}' --region $AWS_REGION | jq -r '.[0][0].VpcId'`
CIDR=`aws ec2 describe-vpcs \
  --filters "Name=vpc-id,Values=$VPC" \
  --query 'Vpcs[*].CidrBlock' \
  --region $AWS_REGION | jq -r '.[0]'`
SG=`aws ec2 describe-instances --filters \
  "Name=private-dns-name,Values=$NODE" \
  --query 'Reservations[*].Instances[*].{SecurityGroups:SecurityGroups}' \
  --region $AWS_REGION | jq -r '.[0][0].SecurityGroups[0].GroupId'`
echo "CIDR - $CIDR,  SG - $SG"
aws ec2 authorize-security-group-ingress \
 --group-id $SG \
 --protocol tcp \
 --port 2049 \
 --cidr $CIDR | jq .

echo "#########################################"
echo "END $date"
echo "#########################################"


