#!/bin/sh

command=`basename $0`
direct=`dirname $0`
trap 'stty echo; echo "${command} aborted"; exit' 1 2 3 15
#
CWD=`pwd`

manifestFile=
manifestGitRepo=

targetDir=

dockerList=

gitUser=
gitEmail=
gitComment=
gitToken=

registryServer=docker.io
userName=
passwd=

dockerSha=
dockerToken=

gitFolder=

push=0
clone=0
remove=0
tmpFile="/tmp/tmpFile$$.tmp"

rmFile()
{
if [ -f "$1" ]; then
    (rm -f "$1") > /dev/null 2>&1
fi
return 0
}

chkFile()
{
(test -f "$1") > /dev/null 2>&1
return $?
}

getGitDir()
{
tmpStr="`echo ${1} | awk '{ i = split($0,arr,"/"); print arr[i--]; }'`"
gitFolder="`echo ${tmpStr} | awk '{str=substr($0,$0,match($0,".git")-1);printf("%s",length(str)>0 ? str : $0);}'`"
return 0
}

#
# Usage
#
usage()
{
#

while [ $# -ne 0 ] ; do
        case $1 in
             -du | --docker-user) userName=$2
                 shift 2;;
             -dp | --docker-password) passwd=$2
                 shift 2;;
             -dr | --registery-server) registryServer=$2
                 shift 2;;                 
             -mf | --manifest-file) manifestFile=$2
                 shift 2;;
             -mgr | --manifest-git-repo) manifestGitRepo=$2
                 shift 2;;
             -td | --target-dir) targetDir=$2
                 shift 2;;
             -dl | --docker-list) dockerList=$2
                 shift 2;;
             -gu | --git-user) gitUser=$2
                 shift 2;;
             -ge | --git-email) gitEmail=$2
                 shift 2;;
             -m | --message) gitComment=$2
                 shift 2;;
             -d | --delete) remove=1 ; shift;;
             -gt | --git-token) gitToken=$2
                 shift 2;;
             --debug) set -xv ; shift;;
             -p | --push) push=1 ; shift;;
             -c | --clone) clone=1 ; shift;;
             -d | --delete) remove=1 ; shift;;
             -?*) show_usage ; break;;
             --) shift ; break;;
             -|*) break;;
        esac
done

if [ "x${gitToken}" = "x" -a "x${API_GIT_TOKEN}" != "x" ]; then
    gitToken="${API_GIT_TOKEN}"
fi

if [ "x${gitToken}" = "x" ]; then
    show_usage
elif [ "x${manifestFile}" = "x" ]; then
    show_usage    
elif [ "x${manifestGitRepo}" = "x" ]; then
    show_usage    
elif [ "x${dockerList}" = "x" ]; then
    show_usage    
elif [ "x${gitUser}" = "x" ]; then
    show_usage    
elif [ "x${gitEmail}" = "x" ]; then
    show_usage    
elif [ "x${gitComment}" = "x" ]; then
    gitComment="Updating product manifest `date`"    
fi

return 0
}

show_usage()
{
echo "${command}: Usage..."
echo "${command}: -mf <manifestFile>"
echo "${command}: -mgr <manifestGitRepoURL>"
echo "${command}: -td <targetDir>"
echo "${command}: -dl <dockerImageList>"
echo "${command}: -gu <gitUser>"
echo "${command}: -ge <gitEmail>"
echo "${command}: -gt <gitToken>"
echo "${command}: -m  <commitMessage>"
echo "${command}: -c -p"

exit 1
}

testDocker()
{
echo "${command}: Test login..."

(docker login https://index.${1}/v1/ -u ${2} -p ${3}) > /dev/null 2>&1
if [ $? -gt 0 ]; then
  return 1
fi

return 0
}

cloneRepo()
{
echo "${command}: Cloning ${1}..."
rmFile "${tmpFile}"
cd /tmp

getGitDir "${1}"

if [ $remove -gt 0 ]; then
    if [ -d "${gitFolder}" ]; then
        echo "${command}: -- Deleting ${gitFolder}..."
        (rm -fr ${gitFolder}) > /dev/null 2>&1
    fi
fi

(git clone ${1}) > "${tmpFile}" 2>&1
if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
fi
rmFile "${tmpFile}"

getGitDir

return 0
}

getImageSha()
{
rmFile "${tmpFile}"
dockerSha=
(docker pull ${1}) > "${tmpFile}" 2>&1
if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
fi

dockerSha=$(docker inspect --format '{{index .RepoDigests 0}}' ${1} \
                | awk '{ str = substr($0,match($0,"@")+1); print str; }') \
            > "${tmpFile}" 2>&1
if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
fi

(docker rmi -f ${1}) > "${tmpFile}" 2>&1
rmFile "${tmpFile}"
return 0
}

getDockerToken()
{
dockerToken=$(curl --silent \
                "https://auth.${1}/token?scope=repository:${2}:pull&service=registry.${1}" \
                | jq -r '.token')
return $?
}

getDockerDigest()
{
dockerSha=$(curl \
    --silent \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    --header "Authorization: Bearer ${2}" \
    "https://registry-1.${1}/v2/${3}/manifests/${4}" \
    | jq -r '.config.digest')
return $?
}

updateManifest()
{
echo "${command}: Updating product manifests..."
getGitDir "${3}"

cd /tmp/${gitFolder}
chkFile "$1"
if [ $? -gt 0 ]; then
    echo "${command}: Unable to locate manifest file ${1}"
    return 1
fi

echo "`echo ${2}`" | sed -n 1'p' | tr ',' '\n' | while read line; 
do
    echo "${command}: - Processing ${line}..."
    productId="`echo ${line} | awk '{ i = split($0,arr,":"); printf arr[1]; }'`"
    dockerImage="`echo ${line} | awk '{ i = split($0,arr,":"); printf("%s:%s",arr[2],arr[3]); }'`"
    dockerBaseImage="`echo ${dockerImage} | awk '{ i = split($0,arr,":"); printf arr[1]; }'`"
    dockerImageTag="`echo ${dockerImage} | awk '{ i = split($0,arr,":"); printf arr[2]; }'`"
    dockerSha=
    echo "${command}: -- Updating ${productId} -> ${dockerBaseImage}..." 
    getDockerToken "${registryServer}" "${dockerBaseImage}"
    getDockerDigest "${registryServer}" "${dockerToken}" "${dockerBaseImage}" "${dockerImageTag}"
    if [ $? -gt 0 -o "x${dockerSha}" = "x" ]; then
        echo "-- Error: Image SHA calculation failed for ${dockerImage}"
        return 1
    fi    
    imageTag=$(yq eval ".${productId}.image.tag" ${1})
    if [ "${imageTag}" != "x" ]; then
        echo "${command}: -- Updating tag ${productId}:${dockerSha}"
        (yq eval --inplace ".${productId}.image.tag=\"${dockerSha}\"" ${1}) > "${tmpFile}" 2>&1
        if [ $? -gt 0 ]; then
            cat "${tmpFile}"
            rmFile "${tmpFile}"
            return 1
        fi
        rmFile "${tmpFile}"
    fi        
done

return 0
}

commitManifest()
{
getGitDir "${1}"

cd /tmp/${gitFolder}
pwd
echo "${command}: Committing product manifests..."
(git config user.name "${2}" && git config --global user.email "${3}") \
    > "${tmpFile}" 2>&1
if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
fi

url=$(printf ${1} | sed "s/https:\/\//https:\/\/token:${4}@/g")
(git remote set-url origin ${url}) > "${tmpFile}" 2>&1
if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
fi
(git commit -am "${5}") > "${tmpFile}" 2>&1
if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
fi
(git push) > "${tmpFile}" 2>&1
if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
fi

rmFile "${tmpFile}"
return 0
}

usage $*

if [ "x${userName}" != "x" -a "x${passwd}" != "x" ]; then
    testDocker "${registryServer}" "${userName}" "${passwd}"
    if [ $? -ne 0 ]; then
        echo "${command}: - Error: Docker Login failed. Please check access to it"
        exit 1
    fi
fi

if [ $clone -gt 0 ]; then
    cloneRepo "${manifestGitRepo}"
    if [ $? -ne 0 ]; then
        cd $CWD
        echo "${command}: - Error: Cloning repo fauled"
        exit 1
    fi
fi    

cd $CWD

updateManifest "${manifestFile}" "${dockerList}" "${manifestGitRepo}"
if [ $? -ne 0 ]; then
    cd $CWD
    echo "${command}: - Error: Updating the product manifest file failed"
    exit 1
fi

cd $CWD

if [ $push -gt 0 ]; then
    commitManifest "${manifestGitRepo}" "${gitUser}" "${gitEmail}" "${gitToken}" "${gitComment}"
    if [ $? -ne 0 ]; then
        cd $CWD
        echo "${command}: - Error: Committing the product manifest file failed"
        exit 1
    fi
fi

cd $CWD

echo "${command}: Done"
exit 0