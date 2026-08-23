# shellcheck disable=SC2006,SC2046,SC2086,SC2129,SC2148,SC2164,SC2230,SC2242
# shellcheck shell=bash
usage() 
{
  cat << EOF

Usage: oracle_lite_docker_build [-h] [-v] [version] [-b] [base_image] [-n] [-t] [image_name:tag]
Builds a lite container image for Oracle Database.

Parameters:
   -h: show config options
   -v: version to build
       Choose one of: 23
                      26
       Default image is 26
   -b: database image to use as a base
   -n: creates nanovos base image based on 'Enterprise Edition' image
   -t: image_name:tag for the generated docker image

EOF

}

# Check container runtime
checkContainerRuntime() 
{
  CONTAINER_RUNTIME=$(which docker 2>/dev/null) ||
    CONTAINER_RUNTIME=$(which podman 2>/dev/null) ||
    {
      echo "No docker or podman executable found in your PATH"
      exit 1
    }

  if "${CONTAINER_RUNTIME}" info | grep -i -q buildahversion; then
    checkPodmanVersion
  else
    checkDockerVersion
  fi
}

# Check Podman version
checkPodmanVersion() 
{
  # Get Podman version
  echo "Checking Podman version."
  PODMAN_VERSION=$("${CONTAINER_RUNTIME}" info --format '{{.host.BuildahVersion}}' 2>/dev/null ||
                   "${CONTAINER_RUNTIME}" info --format '{{.Host.BuildahVersion}}')
  # Remove dot in Podman version
  PODMAN_VERSION=${PODMAN_VERSION//./}

  if [ -z "${PODMAN_VERSION}" ]; then
    exit 1;
  elif [ "${PODMAN_VERSION}" -lt "${MIN_PODMAN_VERSION//./}" ]; then
    echo "Podman version is below the minimum required version ${MIN_PODMAN_VERSION}"
    echo "Please upgrade your Podman installation to proceed."
    exit 1;
  fi
}

# Check Docker version
checkDockerVersion() 
{
  # Get Docker Server version
  echo "Checking Docker version."
  DOCKER_VERSION=$("${CONTAINER_RUNTIME}" version --format '{{.Server.Version }}'|| exit 0)
  # Remove dot in Docker version
  DOCKER_VERSION=${DOCKER_VERSION//./}

  if [ "${DOCKER_VERSION}" -lt "${MIN_DOCKER_VERSION//./}" ]; then
    echo "Docker version is below the minimum required version ${MIN_DOCKER_VERSION}"
    echo "Please upgrade your Docker installation to proceed."
    exit 1;
  fi;
}

env_init()
{
  if [[ "${NANOVOS}" = "false" ]]; then
    export EDITION="FREE"
    ORACLE_SID=FREE
  else
    export EDITION="EE"
    ORACLE_SID=ORCLCDB
  fi
  if [[ "$ORACLE_VERSION" = "23" ]]; then
    HOME_VERSION=26
  else
    HOME_VERSION=$ORACLE_VERSION
  fi
}

log_msg()
{
  MSG=$1
  echo "[" `date` "]" $MSG
}

base_container_init()
{
  export BASE_CONTAINER="myorcldb_base"
  export CONTAINER_BASE=$T_WORK/container_base
  export CONTAINER_OPT_DIR=$CONTAINER_BASE/oracle_opt

  # Create the container base
  mkdir -p $CONTAINER_BASE || { log_msg "$CONTAINER_BASE creation failed"; exit $?; }
  mkdir -p $CONTAINER_OPT_DIR || { log_msg "$CONTAINER_OPT_DIR creation failed"; exit $?; }
  chmod 777 $CONTAINER_OPT_DIR 

  # Copy the docker build scripts to temp base
  cp ${SCRIPT_DIR}/{checkSpace.sh,runUserScripts.sh,decryptPassword.sh} $CONTAINER_BASE/
  cp -r ${BASE_DIR}/data/dockerfiles/${ORACLE_VERSION}/. $CONTAINER_BASE/

  # Pull base container image
  ${CONTAINER_RUNTIME} pull $BASE_IMAGE
}

base_container_remove()
{
  log_msg "... Removing base container $BASE_CONTAINER"
  ${CONTAINER_RUNTIME} rm $BASE_CONTAINER > base_container_remove.out 2>&1
}

base_container_stop()
{
  log_msg "... Stopping base container $BASE_CONTAINER"
  ${CONTAINER_RUNTIME} stop $BASE_CONTAINER > base_container_stop.out 2>&1
}

base_container_start()
{
  log_msg "... Starting base container $BASE_CONTAINER"
  ${CONTAINER_RUNTIME} run --name $BASE_CONTAINER -v $CONTAINER_BASE/oracle_opt:/opt/oracle/oracle_opt:z \
         --detach  $BASE_IMAGE > base_container_start.out 2>&1
}

base_container_copy_data()
{
  log_msg "... Copying data contents from base container"
  ${CONTAINER_RUNTIME} exec -it --user root myorcldb_base /bin/cp -r /opt/oracle/product /opt/oracle/oracle_opt
  if [[ "$NANOVOS" = "false" ]]; then
    ${CONTAINER_RUNTIME} exec -it --user root myorcldb_base /bin/cp -r /opt/oracle/oradata /opt/oracle/oracle_opt
  fi
  if [[ $EDITION = "FREE" ]]; then
    ${CONTAINER_RUNTIME} exec -it --user root myorcldb_base /bin/cp /etc/oratab /opt/oracle/oracle_opt
    ${CONTAINER_RUNTIME} exec -it --user root myorcldb_base /bin/cp /usr/share/doc/oracle-free-${HOME_VERSION}ai/LICENSE /opt/oracle/oracle_opt
  fi
}

base_container_validate_readiness()
{
  while true;
  do
      case `${CONTAINER_RUNTIME} logs myorcldb_base | grep "DATABASE IS READY TO USE" > /dev/null; echo $?` in
      0)
          log_msg "... Database is ready to use"
          break
          ;;
      1)
          log_msg "... Database is not ready yet. Waiting..."
          sleep 60
          ;;
      *)
          log_msg "... Unknown issue in checking database readiness"
          exit -2
          ;;
      esac
  done
}

base_container_modify_db()
{
  log_msg "... Modifying base container database"
  ${CONTAINER_RUNTIME} cp $CONTAINER_BASE/$MODIFY_DB_FILE $BASE_CONTAINER:/opt/oracle/$MODIFY_DB_FILE
  ${CONTAINER_RUNTIME} exec -e ORACLE_SID=${ORACLE_SID} -it $BASE_CONTAINER /opt/oracle/$MODIFY_DB_FILE > base_modify.out 2>&1
}

oracle_home_segregate()
{
  if [[ $EDITION = "FREE" ]]; then
    DBHOME=$CONTAINER_BASE/oracle_opt/product/${HOME_VERSION}ai/dbhomeFree/
  else
    DBHOME=$CONTAINER_BASE/oracle_opt/product/${HOME_VERSION}ai/dbhome_1/
  fi
  log_msg "... Segregating Oracle Home"
  oracle_home_analysis --html-out $T_WORK/oh_analysis.html \
                       --segregate $CONTAINER_BASE/oracle_opt/oh_segregate \
                       --json-out $T_WORK/oh_analysis.json \
                       --lite-build "true" \
                       --version $ORACLE_VERSION \
                       $DBHOME > oracle_home_segregate.out 2>&1
  #Move oracle bin to different location
  mkdir -p $CONTAINER_BASE/oracle_opt/oh_segregate/oracle/bin
  mv $CONTAINER_BASE/oracle_opt/oh_segregate/base/bin/oracle $CONTAINER_BASE/oracle_opt/oh_segregate/oracle/bin
}

oracle_home_compress_data_files()
{
  log_msg "... Compressing data files"
  (
      cd $CONTAINER_BASE/oracle_opt/oradata; 
      if [[ -d FREE/FREEPDB1 ]]; then
        rm -rf FREE/FREEPDB1
      fi
      find "./" -type f -exec gzip --best {} \;
      cd -;
  ) > oracle_home_compress_data_files.out 2>&1
}

oracle_linux_trim()
{
  ${CONTAINER_RUNTIME} build -f ${CONTAINER_BASE}/Dockerfile.OStrim \
    -t ol-trim-img > oracle_linux_trim_build.out
  ${CONTAINER_RUNTIME} run -d --name ol-trim ol-trim-img > oracle_linux_trim_start.out

  while true;
  do
      case `${CONTAINER_RUNTIME} logs ol-trim | grep "OS IMAGE TRIM COMPLETE" > /dev/null; echo $?` in
      0)
          log_msg "... Trimming OS Image complete"
          break
          ;;
      1)
          log_msg "... Trimming still going on. Waiting..."
          sleep 20
          ;;
      *)
          log_msg "... Unknown issue while monitoring OS trimmed status"
          exit -2
          ;;
      esac
  done
  ${CONTAINER_RUNTIME} export -o ol-trim.tar ol-trim > oracle_linux_trim_export.out
  ${CONTAINER_RUNTIME} import ol-trim.tar > oracle_linux_trim_import.out
  IMAGE_ID=$(awk -F: '{print $2}' oracle_linux_trim_import.out)
  ${CONTAINER_RUNTIME} tag $IMAGE_ID ol-trim
  log_msg "... Created lite OS Image"
}

lite_container_build()
{
  log_msg "... Building Oracle Lite Container"
  ${CONTAINER_RUNTIME} build -f ${CONTAINER_BASE}/Dockerfile.lite \
          -t ${IMAGE_NAME} ${CONTAINER_BASE} \
          --build-arg  DB_EDITION=${EDITION} \
          --format docker > lite_container_build.out 2>&1
  log_msg "... Oracle Lite container image build completed"
}

nanovos_container_build()
{
  log_msg "... Building Oracle Nanovos Container"
  ${CONTAINER_RUNTIME} build -f ${CONTAINER_BASE}/Dockerfile.nanovos \
          -t ${IMAGE_NAME} ${CONTAINER_BASE} \
          --build-arg  DB_EDITION=${EDITION} \
          --format docker > nanovos_container_build.out 2>&1
  log_msg "... Oracle Nanovos container image build completed"
}

base_container_cleanup()
{
  log_msg "... Cleanup base container $BASE_CONTAINER and image"
  ${CONTAINER_RUNTIME} image prune --force
  ${CONTAINER_RUNTIME} rm -f $BASE_CONTAINER > base_container_cleanup.out 2>&1
  ${CONTAINER_RUNTIME} rm -f ol-trim >> base_container_cleanup.out 2>&1
  ${CONTAINER_RUNTIME} rmi ol-trim-img >> base_container_cleanup.out 2>&1
  ${CONTAINER_RUNTIME} rmi ol-trim >> base_container_cleanup.out 2>&1
}
