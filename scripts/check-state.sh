#!/usr/bin/env bash
set -euo pipefail

BUCKET="terraform-state-kokko-sample"
REGION="ap-northeast-1"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

deployed=0
total=0

printf "=== Terraform State Check ===\n"
printf "[S3] s3://%s\n" "${BUCKET}"
printf -- "------------------------------\n"

s3_keys=$(aws s3 ls "s3://${BUCKET}/" --recursive --region "${REGION}" \
  | awk '{print $4}' | grep '\.tfstate$' || true)

if [ -z "${s3_keys}" ]; then
  printf "  (state files not found)\n"
else
  while IFS= read -r key; do
    count=$(aws s3 cp "s3://${BUCKET}/${key}" - --region "${REGION}" 2>/dev/null \
      | jq '.resources | length')
    total=$((total + 1))
    if [ "${count}" -gt 0 ]; then
      printf "  ${RED}[DEPLOYED]${NC} %s (%d resources)\n" "${key}" "${count}"
      deployed=$((deployed + 1))
    else
      printf "  ${GREEN}[empty]   ${NC} %s\n" "${key}"
    fi
  done <<< "${s3_keys}"
fi

printf "\n=== Result: "
if [ "${deployed}" -gt 0 ]; then
  printf "${RED}%d/%d state file(s) have deployed resources${NC} ===\n" "${deployed}" "${total}"
  exit 1
else
  printf "${GREEN}all %d state file(s) are empty${NC} ===\n" "${total}"
fi
