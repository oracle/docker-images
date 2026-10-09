#!/usr/bin/env bash

# Resolve and export reproducible base-image build arguments for image wrappers.
# Call resolve_base_image_metadata VERSION DEFAULT_IMAGE BUILD_OPTIONS.
resolve_base_image_metadata() {
  local version="$1"
  local default_image="$2"
  local build_options="${3:-}"
  local token previous="" input="" ref="" digest="" repo_digest="" repository

  # Keep the SIDB base-image defaults consistent for supported ARM builds.
  if [[ -z "${default_image}" && "${HOSTTYPE:-}" == "aarch64" && "${version}" != "26.0.0" ]]; then
    default_image="oraclelinux:8"
  fi

  for token in ${build_options}; do
    if [[ "${token}" == BASE_IMAGE=* || "${token}" == BASE_OL_IMAGE=* ]]; then
      input="${token#*=}"
    elif [[ "${token}" == BASE_IMAGE_REF=* ]]; then
      ref="${token#*=}"
    elif [[ "${token}" == BASE_IMAGE_DIGEST=* ]]; then
      digest="${token#*=}"
    elif [[ "${previous}" == "--build-arg" ]]; then
      case "${token}" in
        BASE_IMAGE=*|BASE_OL_IMAGE=*) input="${token#*=}" ;;
        BASE_IMAGE_REF=*) ref="${token#*=}" ;;
        BASE_IMAGE_DIGEST=*) digest="${token#*=}" ;;
      esac
    fi
    previous="${token}"
  done

  input="${input:-${default_image}}"
  ref="${ref:-${input}}"
  if [[ -z "${digest}" && "${input}" == *@sha256:* ]]; then
    digest="${input##*@}"
  fi

  if [[ -z "${digest}" ]]; then
    echo "Resolving base image digest for ${input} ..."
    "${CONTAINER_RUNTIME:-docker}" pull "${input}" || return 1
    repo_digest="$("${CONTAINER_RUNTIME:-docker}" image inspect --format '{{index .RepoDigests 0}}' "${input}" 2>/dev/null || true)"
    [[ "${repo_digest}" == *@sha256:* ]] || {
      echo "ERROR: no repository digest returned for ${input}" >&2
      return 1
    }
    digest="${repo_digest##*@}"
  fi
  [[ "${digest}" == sha256:* ]] || {
    echo "ERROR: BASE_IMAGE_DIGEST must be a sha256 digest, got ${digest}" >&2
    return 1
  }

  repository="${input%@*}"
  [[ "${repository##*/}" == *:* ]] && repository="${repository%:*}"
  BASE_IMAGE_BUILD_ARGS="--build-arg BASE_IMAGE=${repository}@${digest} --build-arg BASE_OL_IMAGE=${repository}@${digest} --build-arg BASE_IMAGE_REF=${ref} --build-arg BASE_IMAGE_DIGEST=${digest}"
  export BASE_IMAGE_BUILD_ARGS
  echo "Base image reference: ${ref}"
  echo "Base image digest: ${digest}"
}
