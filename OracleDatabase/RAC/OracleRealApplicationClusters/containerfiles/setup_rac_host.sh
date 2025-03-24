#!/bin/bash
#############################
# Copyright 2020-2025, Oracle Corporation and/or affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl
# Author: paramdeep.saini@oracle.com
############################
NODEDIRS=0
SLIMENV=0
IGNOREOSVERSION=0
validate_environment_variables() {
    local podman_compose_file="$1"
    # shellcheck disable=SC2207,SC2016
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
# Function to set up environment variables
setup_nfs_variables() {
    export HEALTHCHECK_INTERVAL=60s
    export HEALTHCHECK_TIMEOUT=120s
    export HEALTHCHECK_RETRIES=240
    export RACNODE1_CONTAINER_NAME=racnodep1
    export RACNODE1_HOST_NAME=racnodep1
    export RACNODE1_PUBLIC_IP=10.0.20.170
    export RACNODE1_CRS_PRIVATE_IP1=192.168.17.170
    export RACNODE1_CRS_PRIVATE_IP2=192.168.18.170
    export INSTALL_NODE=racnodep1
    export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
    export CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\""
    export SCAN_NAME=racnodepc1-scan
    export CRS_ASM_DISCOVERY_STRING="/oradata"
    export CRS_ASM_DEVICE_LIST="/oradata/asm_disk01.img,/oradata/asm_disk02.img,/oradata/asm_disk03.img,/oradata/asm_disk04.img,/oradata/asm_disk05.img"
    export RACNODE2_CONTAINER_NAME=racnodep2
    export RACNODE2_HOST_NAME=racnodep2
    export RACNODE2_PUBLIC_IP=10.0.20.171
    export RACNODE2_CRS_PRIVATE_IP1=192.168.17.171
    export RACNODE2_CRS_PRIVATE_IP2=192.168.18.171
    export DNS_CONTAINER_NAME=rac-dnsserver
    export DNS_HOST_NAME=racdns
    export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
    export RAC_NODE_NAME_PREFIXD="racnoded"
    export RAC_NODE_NAME_PREFIXP="racnodep"
    export DNS_DOMAIN=example.info
    export PUBLIC_NETWORK_NAME="rac_pub1_nw"
    export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
    export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
    export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
    export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
    export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
    export DNS_PUBLIC_IP=10.0.20.25
    export DNS_PRIVATE1_IP=192.168.17.25
    export DNS_PRIVATE2_IP=192.168.18.25
    export CMAN_CONTAINER_NAME=racnodepc1-cman
    export CMAN_HOST_NAME=racnodepc1-cman
    export CMAN_IMAGE_NAME="localhost/oracle/client-cman:21.3.0"
    export CMAN_PUBLIC_IP=10.0.20.15
    export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
    export DB_HOSTDETAILS="HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170"
    export STORAGE_CONTAINER_NAME="racnode-storage"
    export STORAGE_HOST_NAME="racnode-storage"
    export STORAGE_IMAGE_NAME="localhost/oracle/rac-storage-server:latest"
    export ORACLE_DBNAME="ORCLCDB"
    export STORAGE_PUBLIC_IP=10.0.20.80
    export NFS_STORAGE_VOLUME="/scratch/stage/rac-storage/$ORACLE_DBNAME"
    export DB_SERVICE=service:soepdb
    
   if [ -f /etc/selinux/config ]; then
        # Check SELinux state
        selinux_state=$(grep -E '^SELINUX=' /etc/selinux/config | cut -d= -f2)
        
        if [[ "$selinux_state" == "enforcing" || "$selinux_state" == "permissive" || "$selinux_state" == "targeted" ]]; then
            echo "SELinux is enabled with state: $selinux_state. Proceeding with installation."
        else
            echo "SELinux is either disabled or in an unknown state: $selinux_state. Skipping installation."
            echo "INFO: NFS Environment variables setup completed successfully."
            return 0
        fi
    else
        echo "/etc/selinux/config not found. Skipping SELinux check."
        echo "INFO: NFS Environment variables setup completed successfully."
        return 0
    fi


# Create rac-storage.te file
cat <<EOF > /var/opt/rac-storage.te
module rac-storage 1.0;

require {
    type container_init_t;
    type hugetlbfs_t;
    type nfsd_fs_t;
    type rpc_pipefs_t;
    type default_t;
    type kernel_t;
    class filesystem mount;
    class filesystem unmount;
    class file { read write open };
    class dir { read watch };
    class bpf { map_create map_read map_write };
    class system module_request;
    class fifo_file { open read write };
}

#============= container_init_t ==============
allow container_init_t hugetlbfs_t:filesystem mount;
allow container_init_t nfsd_fs_t:filesystem mount;
allow container_init_t rpc_pipefs_t:filesystem mount;
allow container_init_t nfsd_fs_t:file { read write open };
allow container_init_t nfsd_fs_t:dir { read watch };
allow container_init_t rpc_pipefs_t:dir { read watch };
allow container_init_t rpc_pipefs_t:fifo_file { open read write };
allow container_init_t rpc_pipefs_t:filesystem unmount;
allow container_init_t self:bpf map_create;
allow container_init_t self:bpf { map_read map_write };
allow container_init_t default_t:dir read;
allow container_init_t kernel_t:system module_request;
EOF

    # Change directory to /var/opt
    cd /var/opt || { echo "Failed to change directory to /var/opt. Exiting."; exit 1; }

    # Make the policy module
    make -f /usr/share/selinux/devel/Makefile rac-storage.pp || { echo "Failed to make rac-storage.pp. Exiting."; exit 1; }

    # Install the policy module
    semodule -i rac-storage.pp || { echo "Failed to install rac-storage.pp. Exiting."; exit 1; }

    # List installed modules and grep for rac-storage
    semodule -l | grep rac-storage
    
    echo "INFO: NFS Environment variables setup completed successully."
    return 0
}
setup_blockdevices_variables(){
    export HEALTHCHECK_INTERVAL=60s
    export HEALTHCHECK_TIMEOUT=120s
    export HEALTHCHECK_RETRIES=240
    export RACNODE1_CONTAINER_NAME=racnodep1
    export RACNODE1_HOST_NAME=racnodep1
    export RACNODE1_PUBLIC_IP=10.0.20.170
    export RACNODE1_CRS_PRIVATE_IP1=192.168.17.170
    export RACNODE1_CRS_PRIVATE_IP2=192.168.18.170
    export INSTALL_NODE=racnodep1
    export RAC_IMAGE_NAME=localhost/oracle/database-rac:21c
    export CRS_NODES="\"pubhost:racnodep1,viphost:racnodep1-vip;pubhost:racnodep2,viphost:racnodep2-vip\""
    export SCAN_NAME=racnodepc1-scan
    export ASM_DEVICE1="/dev/asm-disk1"
    export ASM_DEVICE2="/dev/asm-disk2"
    export CRS_ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
    export ASM_DISK1="/dev/oracleoci/oraclevdd"
    export ASM_DISK2="/dev/oracleoci/oraclevde"
    export CRS_ASM_DISCOVERY_STRING="/dev/asm-disk*"
    export RACNODE2_CONTAINER_NAME=racnodep2
    export RACNODE2_HOST_NAME=racnodep2
    export RACNODE2_PUBLIC_IP=10.0.20.171
    export RACNODE2_CRS_PRIVATE_IP1=192.168.17.171
    export RACNODE2_CRS_PRIVATE_IP2=192.168.18.171
    export DNS_CONTAINER_NAME=rac-dnsserver
    export DNS_HOST_NAME=racdns
    export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
    export RAC_NODE_NAME_PREFIXD="racnoded"
    export RAC_NODE_NAME_PREFIXP="racnodep"
    export DNS_DOMAIN=example.info
    export PUBLIC_NETWORK_NAME="rac_pub1_nw"
    export PUBLIC_NETWORK_SUBNET="10.0.20.0/24"
    export PRIVATE1_NETWORK_NAME="rac_priv1_nw"
    export PRIVATE1_NETWORK_SUBNET="192.168.17.0/24"
    export PRIVATE2_NETWORK_NAME="rac_priv2_nw"
    export PRIVATE2_NETWORK_SUBNET="192.168.18.0/24"
    export DNS_PUBLIC_IP=10.0.20.25
    export DNS_PRIVATE1_IP=192.168.17.25
    export DNS_PRIVATE2_IP=192.168.18.25
    export CMAN_CONTAINER_NAME=racnodepc1-cman
    export CMAN_HOST_NAME=racnodepc1-cman
    export CMAN_IMAGE_NAME="localhost/oracle/client-cman:21.3.0"
    export CMAN_PUBLIC_IP=10.0.20.15
    export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
    export DB_HOSTDETAILS="HOST=racnodepc1-scan:RULE_ACT=accept,HOST=racnodep1:IP=10.0.20.170"
    export DB_SERVICE=service:soepdb
    echo "INFO: BlockDevices Environment variables setup completed successully."
    return 0
}


# Function to set up DNS Podman container
setup_dns_container() {
    podman-compose up -d ${DNS_CONTAINER_NAME}
    success_message_line="DNS Server IS READY TO USE"
    last_lines=""
    start_time=$(date +%s)

    # Monitor logs until success message is found or timeout occurs
    while true; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if [ $elapsed_time -ge 600 ]; then
            # If 60 minutes elapsed, print a timeout message and exit
            echo "ERROR: Success message not found in DNS Container logs after 10 minutes." >&2
            break
        fi

        # Read the last 10 lines from the logs
        last_lines=$(podman logs --tail 5 "${DNS_CONTAINER_NAME}" 2>&1)

        # Check if the success message is present in the output
        if echo "$last_lines" | grep -q "$success_message_line"; then
            echo "###########################################"
            echo "INFO: DNS Container is setup successfully."
            echo "###########################################"
            break
        fi

        # Print the last 10 lines from the logs
        echo "$last_lines" >&2

        # Sleep for a short duration before checking logs again
        sleep 15
    done
    return 0
}

setup_rac_container() {
    podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up  -d ${RACNODE1_CONTAINER_NAME} 
    podman-compose stop ${RACNODE1_CONTAINER_NAME}

    podman-compose --podman-run-args="-t -i --systemd=always --cpuset-cpus 0-1 --memory 16G --memory-swap 32G" up -d ${RACNODE2_CONTAINER_NAME}
    podman-compose stop ${RACNODE2_CONTAINER_NAME}

    podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
    podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}
    podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE1_CONTAINER_NAME}

    podman network disconnect ${PUBLIC_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
    podman network disconnect ${PRIVATE1_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}
    podman network disconnect ${PRIVATE2_NETWORK_NAME} ${RACNODE2_CONTAINER_NAME}

    podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE1_PUBLIC_IP} ${RACNODE1_CONTAINER_NAME}
    podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP1}  ${RACNODE1_CONTAINER_NAME}
    podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE1_CRS_PRIVATE_IP2}  ${RACNODE1_CONTAINER_NAME}

    podman network connect  ${PUBLIC_NETWORK_NAME} --ip ${RACNODE2_PUBLIC_IP} ${RACNODE2_CONTAINER_NAME}
    podman network connect ${PRIVATE1_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP1}  ${RACNODE2_CONTAINER_NAME}
    podman network connect ${PRIVATE2_NETWORK_NAME} --ip ${RACNODE2_CRS_PRIVATE_IP2}  ${RACNODE2_CONTAINER_NAME}

    podman-compose start ${RACNODE1_CONTAINER_NAME}
    podman-compose start ${RACNODE2_CONTAINER_NAME}

    RAC_LOG="/tmp/orod/oracle_rac_setup.log"
    success_message_line="ORACLE RAC DATABASE IS READY TO USE"
    last_lines=""
    start_time=$(date +%s)

    # Monitor logs until success message is found or timeout occurs
    while true; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if [ $elapsed_time -ge 3600 ]; then
            # If 60 minutes elapsed, print a timeout message and exit
            echo "ERROR: Success message not found in the logs after 60 minutes." >&2
            break
        fi

        # Read the last 10 lines from the logs
        last_lines=$(podman exec ${RACNODE1_CONTAINER_NAME} /bin/bash -c "tail -n 10 $RAC_LOG" 2>&1)

        # Check if the success message is present in the output
        if echo "$last_lines" | grep -q "$success_message_line"; then
            echo "###############################################"
            echo "INFO: Oracle RAC Containers setup successfully."
            echo "###############################################"
            break
        fi

        # Print the last 10 lines from the logs
        echo "$last_lines" >&2

        # Sleep for a short duration before checking logs again
        sleep 15
    done
    return 0

}

setup_storage_container() {
    export ORACLE_DBNAME=ORCLCDB
    mkdir -p $NFS_STORAGE_VOLUME
    rm -rf $NFS_STORAGE_VOLUME/asm_disk0*
    podman rm -f ${STORAGE_CONTAINER_NAME}
    podman-compose --podman-run-args="-t -i --systemd=always" up -d ${STORAGE_CONTAINER_NAME}
    STOR_LOG="/tmp/storage_setup.log"
    export_message_line1="Export list for racnode-storage:"
    export_message_line2="/oradata *"
    last_lines=""
    start_time=$(date +%s)
    # Monitor logs until export message is found or timeout occurs
    while true; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if [ $elapsed_time -ge 1800 ]; then
            # If 30 minutes elapsed, print a timeout message and exit
            echo "ERROR: Successful message not found in the storage container logs after 30 minutes." >&2
            break
        fi
        # Read the last 10 lines from the logs
        last_lines=$(podman exec ${STORAGE_CONTAINER_NAME} tail -n 10 "$STOR_LOG" 2>&1)
        # Check if both lines of the export message are present in the output
        if echo "$last_lines" | grep -q "$export_message_line1" && echo "$last_lines" | grep -q "$export_message_line2"; then
            echo "############################################################"
            echo "INFO: NFS Storage Container exporting /oradata successfully."
            echo "############################################################"
            break
        fi
        # Print the last 10 lines from the logs
        echo "$last_lines" >&2
        # Sleep for a short duration before checking logs again
        sleep 15
    done
    podman volume inspect racstorage &> /dev/null && podman volume rm racstorage
    sleep 5
    podman volume create --driver local \
        --opt type=nfs \
        --opt   o=addr=$STORAGE_PUBLIC_IP,rw,bg,hard,tcp,vers=3,timeo=600,rsize=32768,wsize=32768,actimeo=0 \
        --opt device=$STORAGE_PUBLIC_IP:/oradata \
        racstorage
    return 0
}


setup_cman_container() {
    podman-compose up -d ${CMAN_CONTAINER_NAME}
    success_message_line="CONNECTION MANAGER IS READY TO USE"
    last_lines=""
    start_time=$(date +%s)

    # Monitor logs until success message is found or timeout occurs
    while true; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))

        if [ $elapsed_time -ge 600 ]; then
            # If 60 minutes elapsed, print a timeout message and exit
            echo "ERROR: Success message not found in CMAN Container logs after 10 minutes." >&2
            break
        fi

        # Read the last 10 lines from the logs
        last_lines=$(podman logs --tail 5 "${CMAN_CONTAINER_NAME}" 2>&1)

        # Check if the success message is present in the output
        if echo "$last_lines" | grep -q "$success_message_line"; then
            echo "###########################################"
            echo "INFO: CMAN Container is setup successfully."
            echo "###########################################"
            break
        fi

        # Print the last 10 lines from the logs
        echo "$last_lines" >&2

        # Sleep for a short duration before checking logs again
        sleep 15
    done
    return 0
}

setup_rac_networks() {
    podman network create --driver=bridge --subnet=${PUBLIC_NETWORK_SUBNET} ${PUBLIC_NETWORK_NAME}
    podman network create --driver=bridge --subnet=${PRIVATE1_NETWORK_SUBNET} ${PRIVATE1_NETWORK_NAME} --disable-dns --internal
    podman network create --driver=bridge --subnet=${PRIVATE2_NETWORK_SUBNET} ${PRIVATE2_NETWORK_NAME} --disable-dns --internal
    echo "INFO: Oracle RAC Container Networks setup successfully"
    return 0
}


function DisplayUsage(){
   echo "Usage :
         $0 [<-slimenv> <-nodedirs=dir1,dir2,...,dirn>] [-ignoreOSVersion] [-blockdevices-env|-cleanup|-dns|-networks|-nfs-env|-prepare-rac-env|-rac|-storage] [-help]"
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
        # Enable EPEL repository for Oracle Linux 8
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
    [ -f /var/opt/rac-podman.te ] && cp /var/opt/rac-podman.te /var/opt/rac-podman.te.ORG
    [ -f /var/opt/rac-podman.te ] && rm -rf /var/opt/rac-podman.te
    cat > /var/opt/rac-podman.te <<EOF
module rac-podman  1.0;
 
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
# shellcheck disable=SC2164
    cd /var/opt
    make -f /usr/share/selinux/devel/Makefile rac-podman.pp
    semodule -i rac-podman.pp
    semodule -l | grep rac-pod
    sleep 3
# shellcheck disable=SC2145
    echo "INFO: Setting SEContext for ${nodeHomeValues[@]}"
    for nodeHome in "${nodeHomeValues[@]}"
    do
        echo "INFO: Setting context for $nodeHome"
        # shellcheck disable=SC2086
        semanage fcontext -a -t container_file_t $nodeHome
        # shellcheck disable=SC2086
        restorecon -vF $nodeHome
    done
    return 0
}

# Function to delete and create secrets
delete_and_create_secret() {
    local secret_name=$1
    local file_path=$2

    # Check if the secret exists
    # shellcheck disable=SC2086
    if podman secret inspect $secret_name &> /dev/null; then
        echo "INFO: Deleting existing secret $secret_name..."
        # shellcheck disable=SC2086
        podman secret rm $secret_name
    fi

    # Create the new secret
    echo "INFO: Creating new secret $secret_name..."
    # shellcheck disable=SC2086
    podman secret create $secret_name $file_path
}

create_secrets() {
    # Check if RAC_SECRET environment variable is defined
    if [ -z "$RAC_SECRET" ]; then
        echo "ERROR: RAC_SECRET environment variable is not defined."
        return 1
    fi
    mkdir -p /opt/.secrets/
    # shellcheck disable=SC2086
    echo $RAC_SECRET > /opt/.secrets/pwdfile.txt
    # shellcheck disable=SC2164
    cd /opt/.secrets
    openssl genrsa -out key.pem
    openssl rsa -in key.pem -out key.pub -pubout
    openssl pkeyutl -in pwdfile.txt -out pwdfile.enc -pubin -inkey key.pub -encrypt
    rm -rf /opt/.secrets/pwdfile.txt
    # Delete and create secrets
    delete_and_create_secret "pwdsecret" "/opt/.secrets/pwdfile.enc"
    delete_and_create_secret "keysecret" "/opt/.secrets/key.pem"
    echo "INFO: Secrets created."
    # shellcheck disable=SC2164
    cd -
    return 0
}

check_system_resources() {
    # Check swap space in GB
    swap_space=$(free -g | grep Swap | awk '{print $2}')
    if [ "$swap_space" -ge 16 ]; then
        echo "INFO: Swap space is sufficient ($swap_space GB)."
    else
        echo "ERROR: Swap space is insufficient ($swap_space GB). Minimum 32 GB required."
        return 1
    fi

    # Check physical memory (RAM) in GB
    total_memory=$(free -g | grep Mem | awk '{print $2}')
    if [ "$total_memory" -ge 16 ]; then
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
    # shellcheck disable=SC2006,SC2086
    kernelVersion=`uname -r | cut -d. -f1,2`
    # shellcheck disable=SC2006,SC2086
    majorKernelVersion=`echo ${kernelVersion} | cut -d. -f1`
    # shellcheck disable=SC2006,SC2086
    minorKernelVersion=`echo ${kernelVersion} | cut -d. -f2`

    echo "Running on Kernel [${kernelVersion}]"
# shellcheck disable=SC2006,SC2086
    if [ ${majorKernelVersion} -lt 5 ]; then
    kernelVersionSupported=0
    fi
# shellcheck disable=SC2086
    if [ $majorKernelVersion -eq 5 ]; then
    # shellcheck disable=SC2086
    if [ ${minorKernelVersion} -lt 14 ]; then
        kernelVersionSupported=0
    fi
    fi
# shellcheck disable=SC2166
    if [ $OSVersionSupported -eq 0 -o $kernelVersionSupported -eq 0 ]; then
    if [ ${IGNOREOSVERSION} == "0" ]; then 
        echo "ERROR: OSVersion=${OSVersion}.. KernelVersion=${kernelVersion}. Exiting."
        return 1
    fi
    fi

    echo "Setting kernel parameters in /etc/sysctl.conf"
    sed -i '/fs.aio-max-nr=/d'  /etc/sysctl.conf
    sed -i '/fs.file-max=/d'  /etc/sysctl.conf
    sed -i '/net.core.rmem_max=/d'  /etc/sysctl.conf
    sed -i '/net.core.rmem_default=/d'  /etc/sysctl.conf
    sed -i '/net.core.wmem_max=/d'  /etc/sysctl.conf
    sed -i '/net.core.wmem_default=/d'  /etc/sysctl.conf
    sed -i '/vm.nr_hugepages=/d'  /etc/sysctl.conf

    echo -e "fs.aio-max-nr=1048576\nfs.file-max=6815744\nnet.core.rmem_max=4194304\nnet.core.rmem_default=262144\nnet.core.wmem_max=1048576\nnet.core.wmem_default=262144\nvm.nr_hugepages=16384" >> /etc/sysctl.conf

    if [ ${SLIMENV} -eq 1 ]; then
    echo "INFO: Slim environment specified"
    if [ ${NODEDIRS} -eq 0 ]; then
        echo "ERROR: Missing NodeDirs for SlimEnv. Exiting"
        DisplayUsage
        return 1
    fi
    # shellcheck disable=SC2006,SC2001,SC2086
    nodeHomeDirs=`echo ${node_dirs} | sed -e 's/.*?=\(.*\)/\1/g'`
    # shellcheck disable=SC2162
    IFS=',' read  -a nodeHomeValues <<< "${nodeHomeDirs}"
    for nodeHome in "${nodeHomeValues[@]}"
    do
        echo "INFO: Creating directory $nodeHome"
        # shellcheck disable=SC2086
        mkdir -p $nodeHome
    done
    fi

    if [ ${OSVersionSupported} -eq 1 ]; then
    echo "INFO: Starting chronyd service"
    systemctl start chronyd
    fi
# shellcheck disable=SC2002
    cat /sys/devices/system/clocksource/clocksource0/available_clocksource | grep tsc
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
    echo "INFO: Setting current clocksource"
    echo "tsc">/sys/devices/system/clocksource/clocksource0/current_clocksource
    cat /sys/devices/system/clocksource/clocksource0/current_clocksource

    sed -i -e 's/\(GRUB_CMDLINE_LINUX=.*\)"/\1 tsc"/g' ./grub
    else
    echo "INFO: clock source [tsc] not available on the system"
    fi

    df -h /dev/shm

    # shellcheck disable=SC2006
    freeSHM=`df -h /dev/shm | tail -n +2 | awk '{ print $4 }'`
    echo "INFO: Available shm = [${freeSHM}]"
    # shellcheck disable=SC2086,SC2060,SC2006
    freeSHM=`echo ${freeSHM} | tr -d [:alpha:]`
    # shellcheck disable=SC2129,SC2086
    if [ ${freeSHM} -lt 4 ]; then
    echo "ERROR: Low free space [${freeSHM}] in /dev/shm. Need at least 4GB space. Exiting."
    DisplayUsage
    return 1
    fi
    install_podman
    install_podman_compose
    # shellcheck disable=SC2006
     selinux_state=$(grep -E '^SELINUX=' /etc/selinux/config | cut -d= -f2)   
    if [[ "$selinux_state" == "enforcing" || "$selinux_state" == "permissive" || "$selinux_state" == "targeted" ]]; then
        echo "INFO: SELinux Enabled. Setting up SELinux Context"
        setupSELinuxContext
    else
        echo "INFO: SELinux Disabled."
    fi
    create_secrets || return 1
    check_system_resources || return 1
    echo "INFO: Finished setting up the pre-requisites for Podman-Host"
    return 0
}

cleanup_env(){
    podman rm -f ${DNS_CONTAINER_NAME}
    podman rm -f ${STORAGE_CONTAINER_NAME}
    podman rm -f $RACNODE1_CONTAINER_NAME
    podman rm -f $RACNODE2_CONTAINER_NAME
    podman rm -f ${CMAN_CONTAINER_NAME}
    podman network inspect $PUBLIC_NETWORK_NAME &> /dev/null && podman network rm $PUBLIC_NETWORK_NAME 
    podman network inspect $PRIVATE1_NETWORK_NAME &> /dev/null && podman network rm $PRIVATE1_NETWORK_NAME 
    podman network inspect $PRIVATE2_NETWORK_NAME &> /dev/null && podman network rm $PRIVATE2_NETWORK_NAME
    podman volume inspect racstorage &> /dev/null && podman volume rm racstorage
    echo "INFO: Oracle Container RAC Environment Cleanup Successfully"
    return 0
}

while [ $# -gt 0 ]; do
    case "$1" in 
        -slimenv)
            SLIMENV=1
            ;;
        -nodedirs=*)
            NODEDIRS=1
            node_dirs="${1#*=}"
            ;;
        -ignoreOSVersion)
            IGNOREOSVERSION=1
            ;;
        -help|-h)
            DisplayUsage
            ;;
        -nfs-env)
            setup_nfs_variables || echo "ERROR: Oracle RAC Environment Variables for NFS devices setup has failed."
            ;;
        -blockdevices-env)
            setup_blockdevices_variables || echo "ERROR: Oracle RAC Environment variables for Block devices setup has failed."
            ;;
        -dns)
            validate_environment_variables podman-compose.yml || exit 1
            setup_dns_container || echo "ERROR: Oracle RAC DNS Container Setup has failed."
            ;;
        -rac)
            validate_environment_variables podman-compose.yml || exit 1
            setup_rac_container || echo "ERROR: Oracle RAC Container Setup has failed."
            ;;
        -storage)
            validate_environment_variables podman-compose.yml || exit 1
            setup_storage_container || echo "ERROR: Oracle RAC Storage Container Setup has failed."
            ;;
        -cman)
            validate_environment_variables podman-compose.yml || exit 1
            setup_cman_container || echo "ERROR: Oracle RAC Connection Manager Container Setup has failed."
            ;;
        -cleanup)
            validate_environment_variables podman-compose.yml || exit 1
            cleanup_env || echo "ERROR: Oracle RAC Environment Cleanup Setup has failed."
            ;;
        -networks)
            validate_environment_variables podman-compose.yml || exit  1
            setup_rac_networks || echo "ERROR: Oracle RAC Container Networks setup has failed."
            ;;
        -prepare-rac-env)
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