#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Fetching all NON-DEFAULT VPC IDs..."
VPCS=$(aws ec2 describe-vpcs \
  --filters Name=isDefault,Values=false \
  --query "Vpcs[].VpcId" --output text)

for VPC_ID in $VPCS; do
  echo -e "\n💥 Destroying VPC $VPC_ID and all its children..."

  ## 1) Internet Gateways
  for IGW in $(aws ec2 describe-internet-gateways \
      --filters Name=attachment.vpc-id,Values=$VPC_ID \
      --query "InternetGateways[].InternetGatewayId" --output text); do
    echo "  • Detach IGW $IGW"; aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID
    echo "  • Delete  IGW $IGW";  aws ec2 delete-internet-gateway     --internet-gateway-id $IGW
  done

  ## 2) NAT Gateways + EIPs
  for NAT in $(aws ec2 describe-nat-gateways \
      --filter Name=vpc-id,Values=$VPC_ID \
      --query "NatGateways[].NatGatewayId" --output text); do
    echo "  • Deleting NAT GW $NAT"; 
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT
  done

  for EIP in $(aws ec2 describe-addresses \
      --query "Addresses[?VpcId=='$VPC_ID'].AllocationId" --output text); do
    echo "  • Releasing EIP $EIP"; aws ec2 release-address --allocation-id $EIP
  done

  ## 3) VPC Endpoints
  for EP in $(aws ec2 describe-vpc-endpoints \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "VpcEndpoints[].VpcEndpointId" --output text); do
    echo "  • Delete VPC Endpoint $EP"; aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $EP
  done

  ## 4) Peering Connections
  for PC in $(aws ec2 describe-vpc-peering-connections \
      --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='$VPC_ID'||AccepterVpcInfo.VpcId=='$VPC_ID'].VpcPeeringConnectionId" --output text); do
    echo "  • Delete Peering $PC"; aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PC
  done

  ## 5) Route Tables (remove custom & routes to IGW)
  for RTB in $(aws ec2 describe-route-tables \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "RouteTables[].RouteTableId" --output text); do

    # First, delete any non-main routes to the IGW
    for CIDR in $(aws ec2 describe-route-tables --route-table-ids $RTB \
        --query "RouteTables[0].Routes[?GatewayId!=null].GatewayId" --output text); do
      echo "  • Deleting route via $CIDR in RTB $RTB"
      aws ec2 delete-route --route-table-id $RTB --gateway-id $CIDR || true
    done

    # Disassociate & delete non-main tables
    MAIN=$(aws ec2 describe-route-tables --route-table-ids $RTB \
      --query "RouteTables[0].Associations[?Main==\`true\`]" --output text)
    if [[ -z "$MAIN" ]]; then
      for ASSOC in $(aws ec2 describe-route-tables --route-table-ids $RTB \
          --query "RouteTables[0].Associations[].RouteTableAssociationId" --output text); do
        echo "  • Disassociate RTB assoc $ASSOC"; aws ec2 disassociate-route-table --association-id $ASSOC
      done
      echo "  • Delete RTB $RTB"; aws ec2 delete-route-table --route-table-id $RTB
    fi
  done

  ## 6) Network ACLs (non-default)
  for ACL in $(aws ec2 describe-network-acls \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "NetworkAcls[?Associations==\`[]\` || Associations==null].NetworkAclId" --output text); do
    if [[ "$ACL" != "acl-unknown" ]]; then
      echo "  • Delete NACL $ACL"; aws ec2 delete-network-acl --network-acl-id $ACL || true
    fi
  done

  ## 7) ENIs (just in case)
  for ENI in $(aws ec2 describe-network-interfaces \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "NetworkInterfaces[].NetworkInterfaceId" --output text); do
    echo "  • Delete ENI $ENI"; aws ec2 delete-network-interface --network-interface-id $ENI || true
  done

  ## 8) Security Groups (skip the VPC's default)
  for SG in $(aws ec2 describe-security-groups \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "SecurityGroups[?GroupName!='default'].GroupId" --output text); do
    echo "  • Delete SG $SG"; aws ec2 delete-security-group --group-id $SG || true
  done

  ## 9) Subnets
  for SUB in $(aws ec2 describe-subnets \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "Subnets[].SubnetId" --output text); do
    echo "  • Delete Subnet $SUB"; aws ec2 delete-subnet --subnet-id $SUB || true
  done

  ## 10) DHCP options (if not default)
  DHCP=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID \
    --query "Vpcs[0].DhcpOptionsId" --output text)
  if [[ "$DHCP" != "default" ]]; then
    echo "  • Reset DHCP opts & delete $DHCP"
    aws ec2 associate-dhcp-options --dhcp-options-id default --vpc-id $VPC_ID
    aws ec2 delete-dhcp-options --dhcp-options-id $DHCP
  fi

  ## 11) Finally, delete the VPC
  echo "  ➤ Deleting VPC $VPC_ID"
  aws ec2 delete-vpc --vpc-id $VPC_ID
  echo "✅ VPC $VPC_ID gone!"
done

echo -e "\n🎉 All non-default VPCs have been nuked."
