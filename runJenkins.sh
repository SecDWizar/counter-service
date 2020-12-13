#/bin/bash
# this file creates the jenkins as docker, with jenkins volume and self signed certificate

JENKINSVOLUME="jenkins"
JENKINSIMAGE="jenkins/jenkins:lts"
CN="ec2-35-159-0-27.eu-central-1.compute.amazonaws.com" # CommonName to use in the certificate
JENKINSMODE=HTTPS # or HTTP for non-secure Jenkins

###############################
### DO NOT CHANGE PAST THIS ###
###############################
jenkinsKeystoreFile="jenkins_keystore.jks"
jenkinspersistenceDir="/var/jenkins_home"
jenkinsExternalPort=443
jenkinscontainerName="jenkins"
jenkinsInitialAdminPassword="$jenkinspersistenceDir/secrets/initialAdminPassword"
storepass=${STOREPASS:-"mypassword"} # take from env. if exists, default mypassword
keypass=${KEYPASS:-"mypassword"}     # take from env. if exists, default mypassword
#debug=echo

keytoolCommand="keytool -genkey -noprompt -dname CN=$CN -keyalg RSA -alias selfsigned -keystore $jenkinspersistenceDir/$jenkinsKeystoreFile -storepass $storepass -keypass $keypass -keysize 4096"

# TODO automate the following to allow internal docker client to interact with host (without loosing too much security)
# sudo docker exec -u root -t jenkins bash -c 'groupadd -g 993 docker && usermod -aG docker jenkins'

# FUNCTIONS
badExit() {
    echo "ERROR: $1"
    exit ${2:-1}
}

existsContainer() {
    local containername=$1
    [[ -n $(docker ps -f "name=^$containername$" -q) ]] && return 0 || return 1 # docker ps exit status is 0 even when not found 
}

existsVolume() {
    local volumename=${1-"dummyVolumeName"} # just in case so it couldn't be false negative on empty
    [[ "$volumename" == $(docker volume ls -f "name=^$volumename$" -q) ]] && return 0 || return 1 # docker volume exit status is 0 even when not found
}

createVolume() {
    local volumename=$1
    $debug docker volume create $volumename
}

removeVolume() {
    local volumename=$1
    $debug docker volume remove $volumename
}

createCertificate() {
    $debug docker run --rm -v $JENKINSVOLUME:/$jenkinspersistenceDir -t $JENKINSIMAGE $keytoolCommand
}

getInitialAdminPassword() {
    local initialAdminPassword=

    while ! initialAdminPassword=$(dogetInitialAdminPassword); do
        sleep 1
        echo "this is not a bug, if inital setup already done, feel free to ctrl-c"
    done
    
    echo $initialAdminPassword
}

dogetInitialAdminPassword() {
    $debug docker exec $jenkinscontainerName cat $jenkinsInitialAdminPassword
}

runJenkinsSecure() { 
    $debug docker run                                                   \
        -d                                                              \
        --restart=unless-stopped                                        \
        -p $jenkinsExternalPort:8443                                    \
        --name $jenkinscontainerName                                    \
        -v $JENKINSVOLUME:$jenkinspersistenceDir                        \
        -v $(which docker):/usr/bin/docker                              \
        -v /var/run/docker.sock:/var/run/docker.sock                    \
        $JENKINSIMAGE                                                   \
            --httpPort=-1                                               \
            --httpsPort=8443                                            \
            --httpsKeyStore=$jenkinspersistenceDir/$jenkinsKeystoreFile \
            --httpsKeyStorePassword=$keypass
}

runJenkins() { 
    $debug docker run                                                   \
        -d                                                              \
        --restart=unless-stopped                                        \
        -p $jenkinsExternalPort:8080                                    \
        --name $jenkinscontainerName                                    \
        -v $JENKINSVOLUME:$jenkinspersistenceDir                        \
        -v $(which docker):/usr/bin/docker                              \
        -v /var/run/docker.sock:/var/run/docker.sock                    \
        $JENKINSIMAGE
}

sanitize() {
   # check docker exists
   $debug docker -v || badExit "no docker"
}

init() {
    # elevate if not running as root
    [ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

    sanitize
}

main() {
    init
    # past sanitize here (after init)
    
    # always create the self sign certificate if we need it or not (first time volume is created,
    # so we won't loose configurations later, it's not bad to do so just in case
    rc=0
    if ! existsVolume $JENKINSVOLUME; then
        # create volume
        echo -n "creating volume... "
        createVolume $JENKINSVOLUME && echo -e "\tsuccess" || (( rc++ ))
        
        if (( $rc == 0 )); then
	    # create self sign certificate 
	    echo "create self sign certificate for \"$CN\"... "
	    createCertificate && echo -e "\t success" || (( rc++ ))
                
            if ! (( $rc == 0 )); then
                # remove volume
                echo -n "removing created volume... "
                removeVolume $JENKINSVOLUME && echo -e "\t success" || echo -e "\t FAILURE" 
            fi
        fi
    else 
        echo "volume \"$JENKINSVOLUME\" exists"
    fi
    
    if ! existsContainer $jenkinscontainerName; then
        if (( $rc == 0 )); then
            case "$JENKINSMODE" in 
                HTTPS)
                    # run secure Jenkins
                    echo "running secure jenkins container... "
                    runJenkinsSecure && echo -e "\tsuccess" || echo -e "\tFAILURE"
                    ;;
                HTTP)
                    # run Jenkins
                    echo "running secure jenkins container... "
                    runJenkins && echo -e "\tsuccess" || echo -e "\tFAILURE"
                    ;;
                *)
                    badExit "Usage: $0 [ HTTPS | HTTP ] (default HTTPS)" 20
                    ;;
            esac
        fi
    else 
        echo "container \"$jenkinscontainerName\" exists"
    fi
    
    echo -n "initial admin password: "
    getInitialAdminPassword
}

################################
############# MAIN #############
################################
main
