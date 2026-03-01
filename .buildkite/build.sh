#!/usr/bin/env bash
set -eEuo pipefail
export SHORT_REVISION7=${BUILDKITE_COMMIT:0:7}
export KARPENTER_VERSION="${SANITISED_BRANCH_NAME}-${SHORT_REVISION7}"
# KO is building wrong commit if there are no tags
# Adding dummy tag to avoid "git doesn't contain any tags. Tag info will not be available" warning
git tag --force dummy
CONTROLLER_IMG=$(AWS_DEFAULT_REGION=us-west-2 KO_DOCKER_REPO=035088524874.dkr.ecr.us-west-2.amazonaws.com/public.ecr.aws/karpenter/controller make image | tail -n 1)
if [[ -v BUILDKITE ]]; then
  buildkite-agent annotate --style "info" --context "image-tag" --append "Image: ${CONTROLLER_IMG}"
fi
REGIONS=(
  "us-west-1"
  "us-west-2"
  "us-east-1"
  "ap-southeast-2"
  "ap-northeast-1"
  "eu-west-1"
  "eu-central-1"
)

for r in "${REGIONS[@]}"; do
  AWS_DEFAULT_REGION="${r}" KO_DOCKER_REPO="035088524874.dkr.ecr.${r}.amazonaws.com/public.ecr.aws/karpenter/controller" make image &
done
wait
