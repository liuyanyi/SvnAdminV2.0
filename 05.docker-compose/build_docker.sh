#!/usr/bin/env bash
set -euo pipefail

# 使用当天日期作为版本号，格式为 yyyymmdd
DATE_TAG=$(date +%Y%m%d)

IMAGE_NAME="svnadmin"
DOCKERFILE="03.cicd/svnadmin_docker/dockerfile"

echo "Building ${IMAGE_NAME}:${DATE_TAG} using ${DOCKERFILE} ..."
docker build -t "${IMAGE_NAME}:${DATE_TAG}" -f "${DOCKERFILE}" .
echo "Built ${IMAGE_NAME}:${DATE_TAG}"