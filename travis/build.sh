#!/usr/bin/env bash
set -e

# Login into docker
#TODO: echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

images=""
platforms=""
namespace=mashupmill
image_name=presence-monitor
tag=latest
monitor_branch=master
push=false
auto_tag=false

while [ "$1" != "" ]; do
    case "$1" in
        --auto-tag)
            auto_tag=true
            ;;
        --push)
            push=true
            ;;
        --tag)
            tag=$2
            shift
            ;;
        --monitor-branch)
            monitor_branch=$2
            shift
            ;;
    esac
    shift
done


for arch in $ARCHITECTURES
do
# Build for all architectures and push manifest
  platforms="linux/${arch},${platforms}"
done

platforms=${platforms::-1}

if [[ "$auto_tag" = 'true' ]]; then
  version=$(curl -s https://raw.githubusercontent.com/andrewjfreyer/monitor/${monitor_branch}/monitor.sh | grep 'export version=' | awk -F= '{print $2}')
  if [[ "$monitor_branch" = "master" ]]; then
    tag="${version}"
  else
    tag="${version}-${monitor_branch}"
  fi
fi

# Push multi-arch image
buildctl build --frontend dockerfile.v0 \
      --local dockerfile=. \
      --local context=. \
      --output type=image,push=${push},name=docker.io/${namespace}/${image_name}:${tag} \
      --opt platform=${platforms} \
      --opt filename=./Dockerfile \
      --opt build-arg:MONITOR_BRANCH=${monitor_branch}

# Push image for every arch with arch prefix in tag
for arch in $ARCHITECTURES
do
# Build for all architectures and push manifest
  buildctl build --frontend dockerfile.v0 \
      --local dockerfile=. \
      --local context=. \
      --output type=image,push=${push},name=docker.io/${namespace}/${image_name}:${tag}-${arch//\//} \
      --opt platform=linux/${arch} \
      --opt filename=./Dockerfile \
      --opt build-arg:MONITOR_BRANCH=${monitor_branch} &
done

wait

# verify the unames
# echo "Verifying the images have the expected architecture values"
# docker run --rm ${namespace}/${image_name}:${tag}-amd64 uname -a | grep x86_64
# docker run --rm ${namespace}/${image_name}:${tag}-armv6 uname -a | grep armv6l
# docker run --rm ${namespace}/${image_name}:${tag}-armv7 uname -a | grep armv7l
# docker run --rm ${namespace}/${image_name}:${tag}-arm64 uname -a | grep aarch64
