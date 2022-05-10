#!/bin/sh

command=$(basename $0)
trap 'stty echo; echo "${command} aborted"; exit' 1 2 3 15
CWD=$(pwd)

manifestFile=
manifestGitRepo=
tagStr=".image.tag"

dockerList=
dockerListFile=

gitUser=
gitEmail=
gitComment=
gitToken=

registryServer=docker.io
userName=
password=

dockerSha=
dockerITag=
dockerToken=

gitFolder=

push=0
clone=0
remove=0
tmpFile="/tmp/tmpFile$$.tmp"

rmFile() {
  if [ -f "$1" ]; then
    (rm -f "$1") >/dev/null 2>&1
  fi
  return 0
}

chkFile() {
  (test -f "$1") >/dev/null 2>&1
  return $?
}

getGitDir() {
  tmpStr="$(echo ${1} | awk '{ i = split($0,arr,"/"); print arr[i--]; }')"
  gitFolder="$(echo ${tmpStr} | awk '{str=substr($0,$0,match($0,".git")-1);printf("%s",length(str)>0 ? str : $0);}')"
  return 0
}

#
# Usage
#
usage() {
  while [ $# -ne 0 ]; do
    # GitHub actions double quote where we do not want them...
    word="$(echo "$1" | sed -e 's/^"//' -e 's/"$//')"
    case $word in
    -dt | --docker-tag)
      dockerITag=$2
      shift 2
      ;;
    -du | --docker-user)
      userName=$2
      shift 2
      ;;
    -dp | --docker-password)
      password=$2
      shift 2
      ;;
    -dr | --registery-server)
      registryServer=$2
      shift 2
      ;;
    -mf | --manifest-file)
      manifestFile=$2
      shift 2
      ;;
    -mgr | --manifest-git-repo)
      manifestGitRepo=$2
      shift 2
      ;;
    -dl | --docker-list)
      dockerList=$2
      shift 2
      ;;
    -dlf | --docker-list-file)
      dockerListFile=$2
      shift 2
      ;;
    -gu | --git-user)
      gitUser=$2
      shift 2
      ;;
    -ge | --git-email)
      gitEmail=$2
      shift 2
      ;;
    -gt | --git-token)
      gitToken=$2
      shift 2
      ;;
    -m | --message)
      gitComment=$2
      shift 2
      ;;
    -tgs | --tag-string)
      tagStr=$2
      shift 2
      ;;
    --debug)
      set -xv
      shift
      ;;
    -p | --push)
      push=1
      shift
      ;;
    -c | --clone)
      clone=1
      shift
      ;;
    -d | --delete)
      remove=1
      shift
      ;;
    -?*)
      show_usage
      break
      ;;
    --)
      shift
      break
      ;;
    - | *) break ;;
    esac
  done

  if [ "x${dockerListFile}" != "x" -a "x${dockerListFile}" != "xnull" ]; then
    chkFile "${dockerListFile}"
    if [ $? -ne 0 ]; then
      echo "${command}: - Error: Docker list file does not exist"
      show_usage
    fi
    dockerList="$(cat ${dockerListFile})"
  elif [ "x${manifestFile}" = "x" ]; then
    echo "${command}: - Error: Manifest file is missing"
    show_usage
  elif [ "x${manifestGitRepo}" = "x" ]; then
    echo "${command}: - Error: GitOps repo is missing"
    show_usage
  elif [ "x${dockerList}" = "x" ]; then
    echo "${command}: - Error: Docker image list is missing"
    show_usage
  elif [ "x${gitUser}" = "x" ]; then
    echo "${command}: - Error: GitHub user is missing"
    show_usage
  elif [ "x${gitEmail}" = "x" ]; then
    echo "${command}: - Error: GitHub email is missing"
    show_usage
  elif [ "x${gitToken}" = "x" ]; then
    echo "${command}: - Error: GitHub token is missing"
    show_usage
  elif [ "x${gitComment}" = "x" ]; then
    gitComment="Updating product manifest for ${registryServer} images on $(date)"
  elif [ "x${tagStr}" = "x" ]; then
    tagStr=".image.tag"
  fi

  ## This seems to have some odd limit issue...
  if [ "x${dockerITag}" = "xnull" ]; then
    dockerITag=
  fi

  return 0
}

show_usage() {
  echo "${command}: Usage..."
  echo "${command}: -mf <manifestFile>"
  echo "${command}: -mgr <manifestGitRepoURL>"
  echo "${command}: -dl <dockerImageList>"
  echo "${command}: -dlf <dockerImageListFile>"
  echo "${command}: -gu <gitUser>"
  echo "${command}: -ge <gitEmail>"
  echo "${command}: -gt <gitToken>"
  echo "${command}: -dr <dockerRegistry>"
  echo "${command}: -du <dockerUser>"
  echo "${command}: -dp <dockerPassword>"
  echo "${command}: -tgs <tagString>"
  echo "${command}: -m <commitMessage>"
  echo "${command}: --debug"
  echo "${command}: --clone"
  echo "${command}: --push"
  echo "${command}: --delete"

  exit 1
}

testDocker() {
  # Logins can be flaky - they work sometimes and other times not...
  echo "${command}: Test login..."
  rmFile "${tmpFile}"
  (docker login ${1}/ -u ${2} -p ${3}) >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    if [ "${1}" = "docker.io" ]; then
      echo "${command}: - Test JWT login..."
      jwtToken=$(curl -s -H "Content-Type: application/json" \
        -X POST -d '{"username": "'${2}'", "password": "'${3}'"}' \
        https://hub.docker.com/v2/users/login/ | jq -r .token)
      if [ "x${jwtToken}" = "xnull" ]; then
        cat "${tmpFile}"
        rmFile "${tmpFile}"
        return 1
      fi
    elif [ "${1}" = "ghcr.io" ]; then
      # This is done in the token validation as we already have a token to use
      jwtToken=
    fi
  fi
  rmFile "${tmpFile}"
  return 0
}

cloneRepo() {
  echo "${command}: Cloning ${1}..."
  rmFile "${tmpFile}"
  cd /tmp

  getGitDir "${1}"

  if [ $remove -gt 0 ]; then
    if [ -d "${gitFolder}" ]; then
      echo "${command}: -- Deleting ${gitFolder}..."
      (rm -fr ${gitFolder}) >/dev/null 2>&1
    fi
  fi

  (git clone ${1}) >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi
  rmFile "${tmpFile}"

  getGitDir

  return 0
}

getImageSha() {
  rmFile "${tmpFile}"
  dockerSha=
  (docker pull ${1}) >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi

  dockerSha=$(docker inspect --format '{{index .RepoDigests 0}}' ${1} |
    awk '{ str = substr($0,match($0,"@")+1); print str; }') \
    >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi

  (docker rmi -f ${1}) >"${tmpFile}" 2>&1
  rmFile "${tmpFile}"
  return 0
}

getDockerToken() {
  dockerToken=
  if [ "${1}" = "docker.io" ]; then
    dockerToken=$(curl --silent \
      "https://auth.${1}/token?scope=repository:${2}:pull&service=registry.${1}" |
      jq -r '.token')
  elif [ "${1}" = "ghcr.io" ]; then
    dockerToken=$(curl --silent \
      -u "${3}":"${4}" "https://${1}/token?scope=repository:${2}:pull" |
      jq -r '.token')
  fi

  if [ "x${dockerToken}" = "x" ]; then
    return 1
  fi
  return 0
}

getDockerDigest() {
  rmFile "${tmpFile}"
  if [ "${1}" = "docker.io" ]; then
    (curl -v --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      --header "Authorization: Bearer ${2}" \
      "https://registry-1.${1}/v2/${3}/manifests/${4}") >"${tmpFile}" 2>&1
  elif [ "${1}" = "ghcr.io" ]; then
    (curl -v --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      --header "Authorization: Bearer ${2}" \
      "https://${1}/v2/${3}/manifests/${4}") >"${tmpFile}" 2>&1
  fi

  dockerSha=$(cat "${tmpFile}" | grep -i Docker-Content-Digest | awk '{ print $3 }' | tr '\r' ' ' | \
    awk '{$1=$1;print}')

  retStat=$?
  if [ $retStat -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi
  rmFile "${tmpFile}"

  return $retStat
}

updateManifest() {
  echo "${command}: Updating product manifests..."
  getGitDir "${3}"

  cd /tmp/${gitFolder}
  chkFile "$1"
  if [ $? -gt 0 ]; then
    echo "${command}: Unable to locate manifest file ${1}"
    return 1
  fi

  echo "$(echo ${2})" | sort -u | sed -n 1'p' | tr ',' '\n' | awk '{$1=$1;print}' | while read line; do
    if [ "x${line}" != "x" ]; then
      echo "${command}: - Processing ${line}..."
      productId="$(echo ${line} | awk '{ i = split($0,arr,":"); printf arr[1]; }')"
      dockerImage="$(echo ${line} | awk '{ i = split($0,arr,":"); printf("%s:%s",arr[2],arr[3]); }')"
      dockerBaseImage="$(echo ${dockerImage} | awk '{ i = split($0,arr,":"); printf arr[1]; }')"
      dockerImageTag="$(echo ${dockerImage} | awk '{ i = split($0,arr,":"); printf arr[2]; }')"
      dockerSha=
      if [ "x${productId}" != "x" ]; then
        echo "${command}: -- Updating ${productId} -> ${dockerBaseImage}..."
        if [ "x${dockerITag}" = "x" ]; then
          getDockerToken "${registryServer}" "${dockerBaseImage}" "${4}" "${5}"
          if [ $? -gt 0 -o "x${dockerToken}" = "x" ]; then
            echo "-- Error: Unable to get Docker token"
            return 1
          fi
          getDockerDigest "${registryServer}" "${dockerToken}" "${dockerBaseImage}" "${dockerImageTag}"
          if [ $? -gt 0 -o "x${dockerSha}" = "x" ]; then
            echo "-- Error: Image SHA calculation failed for ${dockerImage}"
            return 1
          fi
        fi
        imageTag=$(yq eval ".${productId}${tagStr}" ${1})
        if [ "${imageTag}" != "x" ]; then
          if [ "x${dockerITag}" = "x" ]; then
            (yq eval --inplace ".${productId}${tagStr}=\"${dockerSha}\"" ${1}) >"${tmpFile}" 2>&1
          else
            (yq eval --inplace ".${productId}${tagStr}=\"${dockerITag}\"" ${1}) >"${tmpFile}" 2>&1
          fi
          if [ $? -gt 0 ]; then
            cat "${tmpFile}"
            rmFile "${tmpFile}"
            return 1
          fi
          rmFile "${tmpFile}"
        fi
      fi
    fi
  done

  return 0
}

commitManifest() {
  getGitDir "${1}"

  cd /tmp/${gitFolder}
  echo "${command}: Committing product manifests..."

  url=$(printf ${1} | sed "s/https:\/\//https:\/\/token:${4}@/g")
  (git remote set-url origin ${url}) >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi

  (git config --local user.email "${3}" &&
    git config --local user.name "${2}") >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi

  export GIT_AUTHOR_NAME="${2}"
  export GIT_AUTHOR_EMAIL="${3}"
  export GIT_COMMITTER_NAME="${2}"
  export GIT_COMMITTER_EMAIL="${3}"

  (git commit --author="${2}" -am "${5}") >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi
  (git push) >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi

  rmFile "${tmpFile}"
  return 0
}

usage $*

if [ "x${userName}" != "x" -a "x${password}" != "x" ]; then
  testDocker "${registryServer}" "${userName}" "${password}"
  if [ $? -ne 0 ]; then
    echo "${command}: - Error: Docker Login failed. Please check access to it"
    exit 1
  fi
fi

if [ $clone -gt 0 ]; then
  cloneRepo "${manifestGitRepo}"
  if [ $? -ne 0 ]; then
    cd $CWD
    echo "${command}: - Error: Cloning repo failed"
    exit 1
  fi
fi

cd $CWD

updateManifest "${manifestFile}" "${dockerList}" "${manifestGitRepo}" "${gitUser}" "${gitToken}"
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
