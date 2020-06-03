#!/usr/bin/env bash

host="${1}"


_Aws::Check_instance() {
  local id="${1:-none}"
  if [[ $(aws ec2 describe-instance-status --instance-ids "${id}" --query 'InstanceStatuses[*].InstanceState.Name' --output text 2>/dev/null) == "running" ]]; then
      if [[ $(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=${id}" --query 'InstanceInformationList[*].PingStatus' --output text) == "Online" ]]; then
        aws ssm start-session --region "${region}" --target "${id}"
      else
        #TODO: check if user has matching keypair to fail back to ssh if possible
        _Log::Die 1 "instance is running, but ssm agent not installed or running"
      fi
  else
      _Log::Die 1 "instance is not running or does not exist"
  fi
}

Aws::Ssh() {
    local host="${1}"
    local region="${2:-us-west-2}"
    _octet_regex='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'
    _private_regex='(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'
    _partial_regex='^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){0,3}$'
    if [[ "${host}" =~ ^i-* ]] || [[ "${host}" =~ ^mi-* ]]; then
        _Aws::Check_instance "${host}"
    elif [[ "${host}" =~ ${_private_regex} ]] && [[ "${host}" =~ ${_octet_regex} ]]; then
        instance_id=$(aws ec2 --region "${region}" describe-network-interfaces --filters Name=addresses.private-ip-address,Values="${host}" --query 'NetworkInterfaces[*].Attachment.InstanceId' --output text)
        _Aws::Check_instance "${instance_id}"
    elif [[ "${host}" =~ ${_octet_regex} ]]; then
        instance_id=$(aws ec2 --region "${region}" describe-network-interfaces --filters Name=addresses.association.public-ip,Values="${host}" --query 'NetworkInterfaces[*].Attachment.InstanceId' --output text)
        _Aws::Check_instance "${instance_id}"
    elif [[ "${host}" =~ ${_partial_regex} ]]; then
        if type fzf &>/dev/null; then
            instance=$(aws ec2 --region "${region}" describe-network-interfaces --filters Name=addresses.private-ip-address,Values="*${host}*" --query 'NetworkInterfaces[*].{id:Attachment.InstanceId,ip:PrivateIpAddress,name:TagSet[?Key==`Name`].Value | [0]}' --output text | grep -e "^i-" | fzf --no-sort --no-preview -1 )
            instance_id=$(echo "${instance}" | { read -r word rest ; echo "${word}" ;} )
            _Aws::Check_instance "${instance_id}"
        fi
    else
    _Log::Die 1 "couldn't find instance by input"
    fi
}