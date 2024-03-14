#!/bin/sh

command=$(basename $0)
trap 'stty echo; echo "${command} aborted"; exit' 1 2 3 15
CWD=$(pwd)

updateScript="${CWD}/updateCompVers.py"

manifestFile=
dstManifestFile=

manifestGitRepo=

component=
version=

gitUser=
gitEmail=
gitComment=
gitToken=

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
    -mf | --src-manifest-file)
      manifestFile=$2
      shift 2
      ;;
    -dmf | --target-manifest-file)
      dstManifestFile=$2
      shift 2
      ;;
    -mgr | --manifest-git-repo)
      manifestGitRepo=$2
      shift 2
      ;;
    -c | --component)
      component=$2
      shift 2
      ;;
    -v | --version)
      version=$2
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
    --debug)
      set -xv
      shift
      ;;
    -p | --push)
      push=1
      shift
      ;;
    --clone)
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

  if [ "x${manifestFile}" = "x" ]; then
    echo "${command}: - Error: Source manifest file is missing"
    show_usage
  elif [ "x${dstManifestFile}" = "x" ]; then
    echo "${command}: - Error: Target manifest file is missing"
    show_usage
  elif [ "x${manifestGitRepo}" = "x" ]; then
    echo "${command}: - Error: GitOps repo is missing"
    show_usage
  elif [ "x${component}" = "x" ]; then
    echo "${command}: - Error: Component name is missing"
    show_usage
  elif [ "x${version}" = "x" ]; then
    echo "${command}: - Error: New version is missing"
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
    gitComment="Updating SBOM manifest on $(date)"
  fi

  return 0
}

show_usage() {
  echo "${command}: Usage..."
  echo "${command}: -mf <srcManifestFile>"
  echo "${command}: -dmf <targetManifestFile>"
  echo "${command}: -mgr <manifestGitRepoURL>"
  echo "${command}: -gu <gitUser>"
  echo "${command}: -ge <gitEmail>"
  echo "${command}: -gt <gitToken>"
  echo "${command}: -c <component>"
  echo "${command}: -v <version>"
  echo "${command}: -m <commitMessage>"
  echo "${command}: --debug"
  echo "${command}: --clone"
  echo "${command}: --push"
  echo "${command}: --delete"

  exit 1
}

cloneRepo() {
  echo "${command}: Cloning ${1}..."
  rmFile "${tmpFile}"
  cd /tmp

  url=$(printf ${1} | sed "s/https:\/\//https:\/\/token:${3}@/g")

  getGitDir "${1}"

  if [ $remove -gt 0 ]; then
    if [ -d "${gitFolder}" ]; then
      echo "${command}: -- Deleting ${gitFolder}..."
      (rm -fr ${gitFolder}) >/dev/null 2>&1
    fi
  fi

  (git clone ${url}) >"${tmpFile}" 2>&1
  if [ $? -gt 0 ]; then
    cat "${tmpFile}"
    rmFile "${tmpFile}"
    return 1
  fi
  rmFile "${tmpFile}"

  getGitDir "${1}"
  if [ ! -d "/tmp/${gitFolder}" ]; then
    echo "${command}: -- Folder not found \"${gitFolder}\"..."
    return 1
  fi
  
  gitFolder=
  return 0
}

updateManifest() {
  echo "${command}: Updating component manifests for ${4}..."
  getGitDir "${3}"

  if [ ! -d "/tmp/${gitFolder}" ]; then
    echo "${command}: Unable to locate folder \"/tmp/${gitFolder}\""
    return 1
  fi
  
  cd "/tmp/${gitFolder}"
  chkFile "$1"
  if [ $? -gt 0 ]; then
    echo "${command}: Unable to locate manifest file \"${1}\" in folder \"/tmp/${gitFolder}\""
    return 1
  fi

  ${updateScript} "${1}" "${2}" "${4}" "${5}" 
  if [ $? -gt 0 ]; then
    echo "${command}: Unable to update manifest file \"${2}\" in folder \"/tmp/${gitFolder}\""
    return 1
  fi

  return 0
}

commitManifest() {
  getGitDir "${1}"

  cd /tmp/${gitFolder}
  echo "${command}: Committing SBOM manifests..."

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

  (git add "${6}") >"${tmpFile}" 2>&1
  (git commit --author="${2}" -am "${5}") >>"${tmpFile}" 2>&1
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

if [ $clone -gt 0 ]; then
  cloneRepo "${manifestGitRepo}" "${gitUser}" "${gitToken}"
  if [ $? -ne 0 ]; then
    cd $CWD
    echo "${command}: - Error: Cloning repo failed"
    exit 1
  fi
fi

cd $CWD

updateManifest "${manifestFile}" "${dstManifestFile}" \
      "${manifestGitRepo}" "${component}" "${version}"
if [ $? -ne 0 ]; then
  cd $CWD
  echo "${command}: - Error: Updating the SBOM manifest file failed"
  exit 1
fi

cd $CWD

if [ $push -gt 0 ]; then
  commitManifest "${manifestGitRepo}" "${gitUser}" "${gitEmail}" \
      "${gitToken}" "${gitComment}" "${dstManifestFile}"
  if [ $? -ne 0 ]; then
    cd $CWD
    echo "${command}: - Error: Committing the SBOM manifest file failed"
    exit 1
  fi
fi

cd $CWD

echo "${command}: Done"
exit 0
