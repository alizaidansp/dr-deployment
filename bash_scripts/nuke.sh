#!/bin/bash

set -e

VPCS=$(aws ec2 describe-vpcs --query "Vpcs[].VpcId" --output text)

for VPC_ID in $VPCS; do
  echo "🔄 Working on VPC: $VPC_ID"

  # Detach and delete Internet Gateways
  IGWS=$(aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=$VPC_ID --query "InternetGateways[].InternetGatewayId" --output text)
  for IGW in $IGWS; do
    echo " 🚪 Detaching and deleting IGW: $IGW"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID || true
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW || true
  done

  # Delete NAT Gateways
  NATS=$(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$VPC_ID --query "NatGateways[].NatGatewayId" --output text)
  for NAT in $NATS; do
    echo " 🌐 Deleting NAT Gateway: $NAT"
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT
  done

  # Release Elastic IPs
  EIPS=$(aws ec2 describe-addresses --query "Addresses[?VpcId=='$VPC_ID'].AllocationId" --output text)
  for EIP in $EIPS; do
    echo " ⚡ Releasing Elastic IP: $EIP"
    aws ec2 release-address --allocation-id $EIP
  done

  # Delete VPC endpoints
  ENDPOINTS=$(aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$VPC_ID --query "VpcEndpoints[].VpcEndpointId" --output text)
  for EP in $ENDPOINTS; do
    echo " 🔌 Deleting VPC endpoint: $EP"
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $EP
  done

  # Delete VPC Peering connections
  PEERINGS=$(aws ec2 describe-vpc-peering-connections --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='$VPC_ID' || AccepterVpcInfo.VpcId=='$VPC_ID'].VpcPeeringConnectionId" --output text)
  for PC in $PEERINGS; do
    echo " 🔗 Deleting VPC Peering Connection: $PC"
    aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PC
  done

  # Disassociate and delete route tables (except main)
  RTBS=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID --query "RouteTables[].RouteTableId" --output text)
  for RTB_ID in $RTBS; do
    IS_MAIN=$(aws ec2 describe-route-tables --route-table-ids $RTB_ID --query "RouteTables[0].Associations[0].Main" --output text)
    if [[ "$IS_MAIN" == "True" ]]; then
      echo " 🛑 Skipping main route table: $RTB_ID"
      continue
    fi

    ASSOC_IDS=$(aws ec2 describe-route-tables --route-table-ids $RTB_ID --query "RouteTables[0].Associations[].RouteTableAssociationId" --output text)
    for ASSOC_ID in $ASSOC_IDS; do
      echo " 🔌 Disassociating route table: $ASSOC_ID"
      aws ec2 disassociate-route-table --association-id $ASSOC_ID
    done

    echo " ❌ Deleting route table: $RTB_ID"
    aws ec2 delete-route-table --route-table-id $RTB_ID
  done

  # Delete network interfaces
  ENIs=$(aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$VPC_ID --query "NetworkInterfaces[].NetworkInterfaceId" --output text)
  for ENI in $ENIs; do
    echo " 🔥 Deleting network interface: $ENI"
    aws ec2 delete-network-interface --network-interface-id $ENI || true
  done

  # Delete security groups (except 'default')
  SGS=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
  for SG in $SGS; do
    echo " 🔐 Deleting security group: $SG"
    aws ec2 delete-security-group --group-id $SG || true
  done

  # Delete subnets
  SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID --query "Subnets[].SubnetId" --output text)
  for SUBNET in $SUBNETS; do
    echo " 🧱 Deleting subnet: $SUBNET"
    aws ec2 delete-subnet --subnet-id $SUBNET || true
  done

  # Delete DHCP options if custom
  DHCP_OPTION_SET=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[0].DhcpOptionsId" --output text)
  if [[ "$DHCP_OPTION_SET" != "default" ]]; then
    echo " 🧼 Disassociating and deleting custom DHCP Options: $DHCP_OPTION_SET"
    aws ec2 associate-dhcp-options --dhcp-options-id default --vpc-id $VPC_ID
    aws ec2 delete-dhcp-options --dhcp-options-id $DHCP_OPTION_SET
  fi

  # Finally delete VPC
  echo "💥 Deleting VPC: $VPC_ID"
  aws ec2 delete-vpc --vpc-id $VPC_ID && echo "✅ VPC $VPC_ID deleted."

done

echo "🎉 All VPCs processed and nuked."
