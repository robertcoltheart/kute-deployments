#!/usr/bin/env bash

set -o errexit

kubeconform_config=("-strict" "-ignore-missing-schemas" "-schema-location" "default" "-schema-location" "/tmp/flux-crd-schemas" "-verbose")
kustomize_flags=("--load-restrictor=LoadRestrictionsNone")
kustomize_config="kustomization.yaml"

download() {
  local url="https://api.github.com/repos/$1/releases"
  local release_url=$(curl -s $url |\
    grep browser_download.*linux[_-]amd64 |\
    cut -d '"' -f 4 |\
    sort -V |\
    tail -n 1)

  mkdir -p .tools

  echo "Downloading $release_url..."

  curl -sL $release_url | tar zxvf - -C .tools
}

install_tools() {
  if [ ! -f .tools/kustomize ]; then
    download 'kubernetes-sigs/kustomize'
  fi

  if [ ! -f .tools/kubeconform ]; then
    download 'yannh/kubeconform'
  fi

  if [ ! -f .tools/yq ]; then
    download 'mikefarah/yq'
    mv .tools/yq_linux_amd64 .tools/yq
  fi
}

verify_yaml() {
  echo "INFO - Downloading Flux OpenAPI schemas"
  mkdir -p /tmp/flux-crd-schemas/master-standalone-strict
  curl -sL https://github.com/fluxcd/flux2/releases/latest/download/crd-schemas.tar.gz | tar zxf - -C /tmp/flux-crd-schemas/master-standalone-strict

  find . -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
  do
    echo "INFO - Validating $file"
    tools/linux/yq e 'true' "$file" > /dev/null
  done
}

verify_clusters() {
  echo "INFO - Validating clusters"
  find ./clusters -maxdepth 2 -type f -name '*.yaml' -print0 | while IFS= read -r -d $'\0' file;
    do
      tools/linux/kubeconform "${kubeconform_config[@]}" "${file}"

      if [[ ${PIPESTATUS[0]} != 0 ]]; then
        exit 1
      fi
  done
}

verify_overlays() {
  echo "INFO - Validating kustomize overlays"
  find . -type f -name $kustomize_config -print0 | while IFS= read -r -d $'\0' file;
    do
      echo "INFO - Validating kustomization ${file/%$kustomize_config}"
      tools/linux/kustomize build "${file/%$kustomize_config}" "${kustomize_flags[@]}" | \
        tools/linux/kubeconform "${kubeconform_config[@]}"

      if [[ ${PIPESTATUS[0]} != 0 ]]; then
        exit 1
      fi
  done
}

# install_tools

verify_yaml
verify_clusters
verify_overlays
