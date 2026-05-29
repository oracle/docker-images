#!/bin/bash
# shellcheck disable=SC2207
# shellcheck disable=SC2164
# shellcheck disable=SC2166
# shellcheck disable=SC2115


validate_environment_variables() {
    local podman_compose_file="$1"
    local env_variables=($(grep -oP '\${\K[^}]*' "$podman_compose_file" | sort -u))
    local missing_variables=()

    for var in "${env_variables[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_variables+=("$var")
        fi
    done

    if [ ${#missing_variables[@]} -eq 0 ]; then
        echo "All required environment variables are present and exported."
        return 0
    else
        echo "The following required environment variables from podman-compose.yml(or may be wrong podman-compose.yml?) are missing or not exported:"
        printf '%s\n' "${missing_variables[@]}"
        return 1
    fi
}
setup_sharding_variables(){
    # Export the variables:
    export PODMANVOLLOC='/scratch/oradata'
    export NETWORK_INTERFACE='ens3'
    export NETWORK_SUBNET="10.0.20.0/20"
    export SIDB_IMAGE='container-registry.oracle.com/database/enterprise:latest'
    export GSM_IMAGE='container-registry.oracle.com/database/gsm:latest'
    export LOCAL_NETWORK=10.0.20
    export healthcheck_interval=30s
    export healthcheck_timeout=3s
    export healthcheck_retries=40
    export CATALOG_OP_TYPE="catalog"
    export ALLSHARD_OP_TYPE="primaryshard"
    export GSM_OP_TYPE="gsm"
    export PWD_SECRET_FILE=/opt/.secrets/pwdfile.enc
    export KEY_SECRET_FILE=/opt/.secrets/key.pem
    export CAT_SHARD_SETUP="true"
    export CATALOG_ARCHIVELOG="true"
    export SHARD_ARCHIVELOG="true"
    export SHARD1_SHARD_SETUP="true"
    export SHARD2_SHARD_SETUP="true"
    export SHARD3_SHARD_SETUP="true"
    export SHARD4_SHARD_SETUP="true"
    export PRIMARY_GSM_SHARD_SETUP="true"
    export STANDBY_GSM_SHARD_SETUP="true"

    export CONTAINER_RESTART_POLICY="always"
    export CONTAINER_PRIVILEGED_FLAG="false"
    export DOMAIN="example.com"
    export DNS_SEARCH="example.com"
    export CAT_CDB="CATCDB"
    export CAT_PDB="CAT1PDB"
    export CAT_HOSTNAME="oshard-catalog-0"
    export CAT_CONTAINER_NAME="catalog"

    export SHARD1_CONTAINER_NAME="shard1"
    export SHARD1_HOSTNAME="oshard1-0"
    export SHARD1_CDB="ORCL1CDB"
    export SHARD1_PDB="ORCL1PDB"

    export SHARD2_CONTAINER_NAME="shard2"
    export SHARD2_HOSTNAME="oshard2-0"
    export SHARD2_CDB="ORCL2CDB"
    export SHARD2_PDB="ORCL2PDB"

    export SHARD3_CONTAINER_NAME="shard3"
    export SHARD3_HOSTNAME="oshard3-0"
    export SHARD3_CDB="ORCL3CDB"
    export SHARD3_PDB="ORCL3PDB"

    export SHARD4_CONTAINER_NAME="shard4"
    export SHARD4_HOSTNAME="oshard4-0"
    export SHARD4_CDB="ORCL4CDB"
    export SHARD4_PDB="ORCL4PDB"

    export PRIMARY_GSM_CONTAINER_NAME="gsm1"
    export PRIMARY_GSM_HOSTNAME="oshard-gsm1"
    export STANDBY_GSM_CONTAINER_NAME="gsm2"
    export STANDBY_GSM_HOSTNAME="oshard-gsm2"


    export PRIMARY_SHARD_DIRECTOR_PARAMS="director_name=sharddirector1;director_region=region1;director_port=1522"
    export PRIMARY_SHARD1_GROUP_PARAMS="group_name=shardgroup1;deploy_as=primary;group_region=region1"
    export PRIMARY_CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2;catalog_chunks=30;repl_type=Native"    
    export PRIMARY_SHARD1_PARAMS="shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1"
    export PRIMARY_SHARD2_PARAMS="shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1"
    export PRIMARY_SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=primary;service_mode=readwrite"
    export PRIMARY_SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=primary;service_mode=readonly"

    export STANDBY_SHARD_DIRECTOR_PARAMS="director_name=sharddirector2;director_region=region1;director_port=1522   "
    export STANDBY_SHARD1_GROUP_PARAMS="group_name=shardgroup1;deploy_as=active_standby;group_region=region1"
    export STANDBY_CATALOG_PARAMS="catalog_host=oshard-catalog-0;catalog_db=CATCDB;catalog_pdb=CAT1PDB;catalog_port=1521;catalog_name=shardcatalog1;catalog_region=region1,region2;catalog_chunks=30;repl_type=Native"
    export STANDBY_SHARD1_PARAMS="shard_host=oshard1-0;shard_db=ORCL1CDB;shard_pdb=ORCL1PDB;shard_port=1521;shard_group=shardgroup1"
    export STANDBY_SHARD2_PARAMS="shard_host=oshard2-0;shard_db=ORCL2CDB;shard_pdb=ORCL2PDB;shard_port=1521;shard_group=shardgroup1"
    export STANDBY_SHARD3_PARAMS="shard_host=oshard3-0;shard_db=ORCL3CDB;shard_pdb=ORCL3PDB;shard_port=1521;shard_group=shardgroup1"
    export STANDBY_SHARD4_PARAMS="shard_host=oshard4-0;shard_db=ORCL4CDB;shard_pdb=ORCL4PDB;shard_port=1521;shard_group=shardgroup1"
    export STANDBY_SERVICE1_PARAMS="service_name=oltp_rw_svc;service_role=standby;service_mode=readwrite"
    export STANDBY_SERVICE2_PARAMS="service_name=oltp_ro_svc;service_role=standby;service_mode=readonly"

    mkdir -p  /opt/containers
    rm -f /opt/containers/shard_host_file && touch /opt/containers/shard_host_file
    sh -c "cat << EOF > /opt/containers/shard_host_file
    127.0.0.1        localhost.localdomain           localhost
    ${LOCAL_NETWORK}.100     oshard-gsm1.example.com         oshard-gsm1
    ${LOCAL_NETWORK}.102     oshard-catalog-0.example.com    oshard-catalog-0
    ${LOCAL_NETWORK}.103     oshard1-0.example.com           oshard1-0
    ${LOCAL_NETWORK}.104     oshard2-0.example.com           oshard2-0
    ${LOCAL_NETWORK}.105     oshard3-0.example.com           oshard3-0
    ${LOCAL_NETWORK}.106     oshard4-0.example.com           oshard4-0
    ${LOCAL_NETWORK}.101     oshard-gsm2.example.com         oshard-gsm2

EOF
"
     # Check if SELinux is enabled (enforcing or permissive)
    if grep -q '^SELINUX=enforcing' /etc/selinux/config || grep -q '^SELINUX=permissive' /etc/selinux/config; then
        if ! grep -q "/opt/containers/shard_host_file" /etc/selinux/targeted/contexts/files/file_contexts.local; then semanage fcontext -a -t container_file_t /opt/containers/shard_host_file; fi
        restorecon -v /opt/containers/shard_host_file
        echo "SELinux is enabled. Updated file contexts."
    fi 
    rm -rf ${PODMANVOLLOC}
    mkdir -p ${PODMANVOLLOC}/scripts
    chown -R 54321:54321 ${PODMANVOLLOC}/scripts
    chmod 755 ${PODMANVOLLOC}/scripts

    mkdir -p ${PODMANVOLLOC}/dbfiles/CATALOG
    chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/CATALOG

    mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL1CDB
    chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL1CDB
    mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL2CDB
    chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL2CDB
    mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL3CDB
    chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL3CDB
    mkdir -p ${PODMANVOLLOC}/dbfiles/ORCL4CDB
    chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/ORCL4CDB

    mkdir -p ${PODMANVOLLOC}/dbfiles/GSMDATA
    chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/GSMDATA

    mkdir -p ${PODMANVOLLOC}/dbfiles/GSM2DATA
    chown -R 54321:54321 ${PODMANVOLLOC}/dbfiles/GSM2DATA


    chmod 755 ${PODMANVOLLOC}/dbfiles/CATALOG
    chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL1CDB
    chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL2CDB
    chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL3CDB
    chmod 755 ${PODMANVOLLOC}/dbfiles/ORCL4CDB
    chmod 755 ${PODMANVOLLOC}/dbfiles/GSMDATA
    chmod 755 ${PODMANVOLLOC}/dbfiles/GSM2DATA
    create_secrets || return 1
    # List of files
    files=(
        "${PODMANVOLLOC}/dbfiles/CATALOG"
        "/opt/containers/shard_host_file"
        "${PODMANVOLLOC}/dbfiles/ORCL1CDB"
        "${PODMANVOLLOC}/dbfiles/ORCL2CDB"
        "${PODMANVOLLOC}/dbfiles/GSMDATA"
        "${PODMANVOLLOC}/dbfiles/GSM2DATA"
        "${PODMANVOLLOC}/dbfiles/ORCL3CDB"
        "${PODMANVOLLOC}/dbfiles/ORCL4CDB"
    )

    if grep -q '^SELINUX=enforcing' /etc/selinux/config || grep -q '^SELINUX=permissive' /etc/selinux/config; then
    for file in "${files[@]}"; do
        # Check if file context exists
        if ! matchpathcon -V "$file" | grep -q 'container_file_t'; then
            # If not, add file context
            semanage fcontext -a -t container_file_t "$file"
        fi
        restorecon -v "$file"
    done
        echo "Updated file contexts."
    else
        echo "SELinux is not enabled."
    fi
    echo "Sharding Environment Variables are setup successfully."
    return 0
}
setup_catalog_container(){
    podman-compose up -d catalog_db
    return 0
}

setup_shard1_container(){
    podman-compose up -d shard1_db
    return 0
}
setup_shard2_container(){
    podman-compose up -d shard2_db
    return 0
}

setup_shard3_container(){
    podman-compose up -d shard3_db
    return 0
}
setup_shard4_container(){
    podman-compose up -d shard4_db
    return 0
}
setup_gsm_primary_container(){
    podman-compose up -d primary_gsm
    return 0
}
setup_gsm_standby_container(){
    podman-compose up -d standby_gsm
    return 0
}


function DisplayUsage(){
   echo "Usage :
         $0 [-ignoreOSVersion] [-cleanup|-export-sharding-env|-prepare-sharding-env|-sharding-deploy] [-help]"
   return 0
}

# Function to check if a command is available
check_command() {
    if ! command -v "$1" &>/dev/null; then
        return 1
    fi
}

# Function to install Podman
install_podman() {
    if ! check_command podman; then
        echo "INFO: Podman is not installed. Installing..."
        sudo dnf install -y podman
    else
        echo "INFO: Podman is already installed."
    fi
    return 0
}

# Function to install Podman-Compose
install_podman_compose() {
    if ! check_command podman-compose; then
        echo "INFO: Podman-Compose is not installed. Installing..."
        # Enable EPEL repository for Oracle Linux 9
        sudo dnf config-manager --enable ol8_developer_EPEL
        # Install Podman-Compose
        sudo dnf install -y podman-compose
    else
        echo "INFO: Podman-Compose is already installed."
    fi
    return 0
}

function setupSELinuxContext(){

    dnf install selinux-policy-devel -y
    [ -f /var/opt/sharding-podman.te ] && cp /var/opt/sharding-podman.te /var/opt/sharding-podman.te.ORG
    [ -f /var/opt/sharding-podman.te ] && rm -rf /var/opt/sharding-podman.te
    cat > /var/opt/sharding-podman.te <<EOF
module sharding-podman  1.0;
 
require {
        type kernel_t;
        class system syslog_read;
        type container_runtime_t;
        type container_init_t;
        class file getattr;
        type container_file_t;
        type lib_t;
        type textrel_shlib_t;
        type unlabeled_t;
        class file read;
        type bin_t;
        class file { execmod execute map setattr };     
}

#============= container_init_t ==============
allow container_init_t container_runtime_t:file getattr;
allow container_init_t bin_t:file map;
allow container_init_t bin_t:file execute;
allow container_init_t container_file_t:file execmod;
allow container_init_t lib_t:file execmod;
allow container_init_t textrel_shlib_t:file setattr;
allow container_init_t kernel_t:system syslog_read;
allow container_init_t unlabeled_t:file read;
EOF

    cd /var/opt
    yes | make -f /usr/share/selinux/devel/Makefile sharding-podman.pp
    semodule -l | grep -q "sharding-podman" && semodule -r sharding-podman
    semodule -i sharding-podman.pp
    semodule -l | grep rac-pod
    sleep 3
    cd - 
}

# Function to delete and create secrets
delete_and_create_secret() {
    local secret_name=$1
    local file_path=$2

    # Check if the secret exists
    if podman secret inspect $secret_name &> /dev/null; then
        echo "INFO: Deleting existing secret $secret_name..."
        podman secret rm $secret_name
    fi

    # Create the new secret
    echo "INFO: Creating new secret $secret_name..."
    podman secret create $secret_name $file_path
}

create_secrets() {
    # Check if SHARDING_SECRET environment variable is defined
    if [ -z "$SHARDING_SECRET" ]; then
        echo "ERROR: SHARDING_SECRET environment variable is not defined."
        return 1
    fi
    mkdir -p /opt/.secrets/
    echo $SHARDING_SECRET > /opt/.secrets/pwdfile.txt
    cd /opt/.secrets
    openssl genrsa -out key.pem
    openssl rsa -in key.pem -out key.pub -pubout
    openssl pkeyutl -in pwdfile.txt -out pwdfile.enc -pubin -inkey key.pub -encrypt
    rm -rf /opt/.secrets/pwdfile.txt
    # Delete and create secrets
    delete_and_create_secret "pwdsecret" "/opt/.secrets/pwdfile.enc"
    delete_and_create_secret "keysecret" "/opt/.secrets/key.pem"
    echo "INFO: Secrets created."
    chown 54321:54321 /opt/.secrets/pwdfile.enc
    chown 54321:54321 /opt/.secrets/key.pem
    chown 54321:54321 /opt/.secrets/key.pub
    chmod 400 /opt/.secrets/pwdfile.enc
    chmod 400 /opt/.secrets/key.pem
    chmod 400 /opt/.secrets/key.pub
    # List of files
    files=(
        "/opt/.secrets/pwdfile.enc"
        "/opt/.secrets/key.pem"
        /opt/.secrets/key.pub
    )
    if grep -q '^SELINUX=enforcing' /etc/selinux/config || grep -q '^SELINUX=permissive' /etc/selinux/config; then
        for file in "${files[@]}"; do
            # Check if file context exists
            if ! grep -q "$(basename "$file")" /etc/selinux/targeted/contexts/files/file_contexts.local; then
                # If not, add file context
                semanage fcontext -a -t container_file_t "$file"
                restorecon -v "$file"
            fi
        done
        echo "SELinux is enabled. Updated file contexts."

    fi

    cd -
    return 0
}

check_system_resources() {
    # # Check swap space in GB
    # swap_space=$(free -g | grep Swap | awk '{print $2}')
    # if [ "$swap_space" -ge 32 ]; then
    #     echo "INFO: Swap space is sufficient ($swap_space GB)."
    # else
    #     echo "ERROR: Swap space is insufficient ($swap_space GB). Minimum 32 GB required."
    #     return 1
    # fi

    # Check physical memory (RAM) in GB
    total_memory=$(free -g | grep Mem | awk '{print $2}')
    if [ "$total_memory" -ge 32 ]; then
        echo "INFO: Physical memory is sufficient ($total_memory GB)."
    else
        echo "ERROR: Physical memory is insufficient ($total_memory GB). Minimum 32 GB required."
        return 1
    fi

    # Both swap space and physical memory meet the requirements
    return 0
}

setup_host_prepreq(){
 kernelVersionSupported=1
    # shellcheck disable=SC2317
    # shellcheck disable=SC2006
    OSVersion=`grep "Oracle Linux Server release 8" /etc/oracle-release`
    OSstatus=$?
    if [ ${OSstatus} -eq 0 ]; then
    OSVersionSupported=1
    else
    OSVersionSupported=0
    fi

    echo "INFO: Setting Podman env on OS [${OSVersion}]"
    # shellcheck disable=SC2006
    kernelVersion=`uname -r | cut -d. -f1,2`
    # shellcheck disable=SC2006
    majorKernelVersion=`echo ${kernelVersion} | cut -d. -f1`
    # shellcheck disable=SC2006
    minorKernelVersion=`echo ${kernelVersion} | cut -d. -f2`

    echo "Running on Kernel [${kernelVersion}]"

    if [ ${majorKernelVersion} -lt 5 ]; then
    kernelVersionSupported=0
    fi

    if [ $majorKernelVersion -eq 5 ]; then
    if [ ${minorKernelVersion} -lt 14 ]; then
        kernelVersionSupported=0
    fi
    fi

    if [ $OSVersionSupported -eq 0 -o $kernelVersionSupported -eq 0 ]; then
    if [ ${IGNOREOSVERSION} == "0" ]; then 
        echo "ERROR: OSVersion=${OSVersion}.. KernelVersion=${kernelVersion}. Exiting."
        return 1
    fi
    fi
    install_podman
    install_podman_compose
    # shellcheck disable=SC2006
    SEMode=`getenforce`
    if [ "${SEMode}" == "Enforcing" ]; then
    echo "INFO: SELinux Enabled. Setting up SELinux Context"
    setupSELinuxContext
    else
    echo "INFO: SELinux Disabled."

    fi
    check_system_resources || return 1
    echo "INFO: Finished setting up the pre-requisites for Podman-Host"
    return 0
}
cleanup_env(){
    podman rm -f ${CAT_CONTAINER_NAME}
    podman rm -f ${SHARD1_CONTAINER_NAME}
    podman rm -f $SHARD2_CONTAINER_NAME
    podman rm -f $SHARD3_CONTAINER_NAME
    podman rm -f ${SHARD4_CONTAINER_NAME}
    podman rm -f ${PRIMARY_GSM_CONTAINER_NAME}
    podman rm -f ${STANDBY_GSM_CONTAINER_NAME}
    podman network inspect shard_pub1_nw &> /dev/null && podman network rm shard_pub1_nw
    rm -rf ${PODMANVOLLOC}/*
    echo "INFO: Oracle Globally Distributed Database Container Environment Cleanup Successfully"
    return 0
}

while [ $# -gt 0 ]; do
    case "$1" in 
        -ignoreOSVersion)
            IGNOREOSVERSION=1
            ;;
        -help|-h)
            DisplayUsage
            ;;         
        -export-sharding-env)
            setup_sharding_variables || echo "ERROR: Oracle Sharding Environment Variables setup has failed."
            ;;
        -deploy-catalog)
            validate_environment_variables podman-compose.yml || exit 1
            setup_catalog_container || echo "ERROR: Oracle Catalog Container Setup has failed."
            ;;
        -deploy-shard1)
            validate_environment_variables podman-compose.yml || exit 1
            setup_shard1_container || echo "ERROR: Oracle Shard1 Container Setup has failed."
            ;;
        -deploy-shard2)
            validate_environment_variables podman-compose.yml || exit 1
            setup_shard2_container || echo "ERROR: Oracle Shard2 Container Setup has failed."
            ;;
        -deploy-shard3)
            validate_environment_variables podman-compose.yml || exit 1
            setup_shard3_container || echo "ERROR: Oracle Shard4 Container Setup has failed."
            ;;
        -deploy-shard4)
            validate_environment_variables podman-compose.yml || exit 1
            setup_shard4_container || echo "ERROR: Oracle Shard4 Container Setup has failed."
            ;;
        -deploy-gsm-primary)
            validate_environment_variables podman-compose.yml || exit 1
            setup_gsm_primary_container || echo "ERROR: Oracle Primary GSM Container Setup has failed."
            ;;
        -deploy-gsm-standby)
            validate_environment_variables podman-compose.yml || exit 1
            setup_gsm_standby_container || echo "ERROR: Oracle Standby GSM Container Setup has failed."
            ;;
        -cleanup)
            validate_environment_variables podman-compose.yml || exit 1
            cleanup_env || echo "ERROR: Oracle RAC Environment Cleanup Setup has failed."
            ;;
        -prepare-sharding-env)
            setup_host_prepreq || echo "ERROR: Oracle RAC preparation setups have failed."
            ;;
        *)
            printf "***************************\n"
            # shellcheck disable=SC2059
            printf "* Error: Invalid argument [$1] specified.*\n"
            printf "***************************\n"
            DisplayUsage
            ;;
    esac
    shift
done

