#!/usr/bin/env bash

BUILDER_TAG=$(cat .buildkite/Dockerfile hack/toolchain.sh Makefile go.mod go.sum | md5sum | cut -d ' ' -f 1)
export BUILDER_TAG

if aws ecr describe-images --repository-name=karpenter-builder --image-ids=imageTag="${BUILDER_TAG}" >/dev/null 2>&1; then
  echo "--- karpenter builder image ${BUILDER_TAG} already exists, reusing" >&2
  # For main branch, ensure the main-${BUILDER_TAG} tag exists (to avoid lifecycling the image out of existence)
  if [[ "${BUILDKITE_BRANCH}" == "main" ]] &&
    ! aws ecr describe-images --repository-name=karpenter-builder --image-ids=imageTag="main-${BUILDER_TAG}" >/dev/null 2>&1; then
    echo "--- Tagging karpenter builder image ${BUILDER_TAG} as main-${BUILDER_TAG}" >&2
    MANIFEST=$(aws ecr batch-get-image --repository-name karpenter-builder --image-ids imageTag="${BUILDER_TAG}" --output text --query 'images[].imageManifest')
    aws ecr put-image --repository-name karpenter-builder --image-tag "main-${BUILDER_TAG}" --image-manifest "$MANIFEST" >&2
  fi
  ### Output dummy wait
  echo "  - wait: ~
    key: karpenter-builder
"
else
  echo "--- Building the builder image..." >&2
  cat <<EOF
  - label: ":docker: Build the builder"
    agents: { queue: eng-prod-us-west-2-intel-linux-build-large }
    plugins:
        - ssh://git@github.com/ROKT/docker-ecr-buildkite-plugin.git#v1.47.0:
            name: karpenter-builder
            regions: [us-west-2]
            default-branch: main
            security:
              snyk: false
              iac-scan: false
            repo-configuration:
              pull-policy-file: .buildkite/repository-policy.json
              tags:
                team: rokt-global-infrastructure
                service: karpenter-builder
              lifecycle-policy:
                branch-retain-counts:
                  - main:100
                other-branches-retain-count: 100
                keep-untagged-max-days: 3
            docker-configuration:
              driver: "buildx"
              platforms:
                - linux/amd64
              dockerfile: .buildkite/Dockerfile
              cache-from:
                - ecr://karpenter-builder:main-latest
                - ecr://karpenter-builder:${SANITISED_BRANCH_NAME}-latest
              tags:
                - ${SANITISED_BRANCH_NAME}-latest
                - ${SANITISED_BRANCH_NAME}-${BUILDKITE_COMMIT}
                - ${BUILDER_TAG}
              add-latest-tag: false
EOF
fi

envsubst < .buildkite/pipeline.yaml
