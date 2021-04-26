#!/bin/bash

# Azure CLI prompt helper for bash/zsh
# inspired by Jon Mosco's prompt helper for Kubernetes
# Displays current subscription

# Copyright 2018 Alexis Plantin
#
#  Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Debug
[[ -n $DEBUG ]] && set -x

# Default values for the prompt
# Override these values in ~/.zshrc or ~/.bashrc
AZ_PS1_BINARY="${AZ_PS1_BINARY:-az}"
AZ_PS1_JQ_BINARY="${AZ_PS1_JQ_BINARY:-jq}"
AZ_PS1_PREFIX="${AZ_PS1_PREFIX-(}"
AZ_PS1_SUFFIX="${AZ_PS1_SUFFIX-)}"
AZ_PS1_SUBSCRIPTION_COLOR="${AZ_PS1_SUBSCRIPTION_COLOR-red}"
AZ_PS1_BG_COLOR="${AZ_PS1_BG_COLOR}"
AZ_PS1_CLOUD_CONFIG_FILE="${HOME}/.azure/clouds.config"
AZ_PS1_CONFIG_FILE="${HOME}/.azure/config"
AZ_PS1_AZURE_PROFILE_FILE="${HOME}/.azure/azureProfile.json"
AZ_PS1_DISABLE_PATH="${HOME}/.azure/az-ps1/disabled"

# Determine our shell
if [ "${ZSH_VERSION-}" ]; then
  AZ_PS1_SHELL="zsh"
elif [ "${BASH_VERSION-}" ]; then
  AZ_PS1_SHELL="bash"
fi

_az_ps1_init() {
  [[ -f "${AZ_PS1_DISABLE_PATH}" ]] && AZ_PS1_ENABLED=off

  # Set the correct md5 command
  if [[ `uname` == 'FreeBSD' ]] || [[ `uname` == 'Darwin' ]]; then
    AZ_PS1_MD5_BINARY="md5"
  elif [[ `uname` == 'Linux' ]]; then
    AZ_PS1_MD5_BINARY="md5sum"
  fi

  AZ_MD5SUM_CACHE=$AZ_MD5SUM_CURRENT

  case "${AZ_PS1_SHELL}" in
    "zsh")
      _AZ_PS1_OPEN_ESC="%{"
      _AZ_PS1_CLOSE_ESC="%}"
      _AZ_PS1_DEFAULT_BG="%k"
      _AZ_PS1_DEFAULT_FG="%f"
      setopt PROMPT_SUBST
      autoload -U add-zsh-hook
      add-zsh-hook precmd _az_ps1_update_cache
      zmodload zsh/stat
      zmodload zsh/datetime
      ;;
    "bash")
      _AZ_PS1_OPEN_ESC=$'\001'
      _AZ_PS1_CLOSE_ESC=$'\002'
      _AZ_PS1_DEFAULT_BG=$'\033[49m'
      _AZ_PS1_DEFAULT_FG=$'\033[39m'
      PROMPT_COMMAND="_az_ps1_update_cache;${PROMPT_COMMAND:-:}"
      ;;
  esac
}

_az_ps1_color_fg() {
  local AZ_PS1_FG_CODE
  case "${1}" in
    black) AZ_PS1_FG_CODE=0;;
    red) AZ_PS1_FG_CODE=1;;
    green) AZ_PS1_FG_CODE=2;;
    yellow) AZ_PS1_FG_CODE=3;;
    blue) AZ_PS1_FG_CODE=4;;
    magenta) AZ_PS1_FG_CODE=5;;
    cyan) AZ_PS1_FG_CODE=6;;
    white) AZ_PS1_FG_CODE=7;;
    # 256
    [0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-6]) AZ_PS1_FG_CODE="${1}";;
    *) AZ_PS1_FG_CODE=default
  esac

  if [[ "${AZ_PS1_FG_CODE}" == "default" ]]; then
    AZ_PS1_FG_CODE="${_AZ_PS1_DEFAULT_FG}"
    return
  elif [[ "${AZ_PS1_SHELL}" == "zsh" ]]; then
    AZ_PS1_FG_CODE="%F{$AZ_PS1_FG_CODE}"
  elif [[ "${AZ_PS1_SHELL}" == "bash" ]]; then
    if tput setaf 1 &> /dev/null; then
      AZ_PS1_FG_CODE="$(tput setaf ${AZ_PS1_FG_CODE})"
    elif [[ $AZ_PS1_FG_CODE -ge 0 ]] && [[ $AZ_PS1_FG_CODE -le 256 ]]; then
      AZ_PS1_FG_CODE="\033[38;5;${AZ_PS1_FG_CODE}m"
    else
      AZ_PS1_FG_CODE="${_AZ_PS1_DEFAULT_FG}"
    fi
  fi
  echo ${_AZ_PS1_OPEN_ESC}${AZ_PS1_FG_CODE}${_AZ_PS1_CLOSE_ESC}
}

_az_ps1_color_bg() {
  local AZ_PS1_BG_CODE
  case "${1}" in
    black) AZ_PS1_BG_CODE=0;;
    red) AZ_PS1_BG_CODE=1;;
    green) AZ_PS1_BG_CODE=2;;
    yellow) AZ_PS1_BG_CODE=3;;
    blue) AZ_PS1_BG_CODE=4;;
    magenta) AZ_PS1_BG_CODE=5;;
    cyan) AZ_PS1_BG_CODE=6;;
    white) AZ_PS1_BG_CODE=7;;
    # 256
    [0-9]|[1-9][0-9]|[1][0-9][0-9]|[2][0-4][0-9]|[2][5][0-6]) AZ_PS1_BG_CODE="${1}";;
    *) AZ_PS1_BG_CODE=$'\033[0m';;
  esac

  if [[ "${AZ_PS1_BG_CODE}" == "default" ]]; then
    AZ_PS1_FG_CODE="${_AZ_PS1_DEFAULT_BG}"
    return
  elif [[ "${AZ_PS1_SHELL}" == "zsh" ]]; then
    AZ_PS1_BG_CODE="%K{$AZ_PS1_BG_CODE}"
  elif [[ "${AZ_PS1_SHELL}" == "bash" ]]; then
    if tput setaf 1 &> /dev/null; then
      AZ_PS1_BG_CODE="$(tput setab ${AZ_PS1_BG_CODE})"
    elif [[ $AZ_PS1_BG_CODE -ge 0 ]] && [[ $AZ_PS1_BG_CODE -le 256 ]]; then
      AZ_PS1_BG_CODE="\033[48;5;${AZ_PS1_BG_CODE}m"
    else
      AZ_PS1_BG_CODE="${DEFAULT_BG}"
    fi
  fi
  echo ${OPEN_ESC}${AZ_PS1_BG_CODE}${CLOSE_ESC}
}

_az_ps1_binary_check() {
  command -v $1 >/dev/null
}

_az_ps1_split() {
  type setopt >/dev/null 2>&1 && setopt SH_WORD_SPLIT
  local IFS=$1
  echo $2
}

_az_ps1_update_cache() {
  [[ "${AZ_PS1_ENABLED}" == "off" ]] && return

  if ! _az_ps1_binary_check "${AZ_PS1_BINARY}"; then
    # No ability to fetch subscription; display N/A.
    AZ_PS1_SUBSCRIPTION="BINARY-N/A"
    return
  fi

  AZ_MD5SUM_CURRENT="$($AZ_PS1_MD5_BINARY $AZ_PS1_CLOUD_CONFIG_FILE)$($AZ_PS1_MD5_BINARY $AZ_PS1_CONFIG_FILE)"

  if [[ "${AZ_MD5SUM_CURRENT}" != "${AZ_MD5SUM_CACHE}" ]]; then
    # The Azure configuration file changed, fetch
    AZ_MD5SUM_CACHE=${AZ_MD5SUM_CURRENT}
    _az_ps1_get_subscription
    return
  fi

}

_az_ps1_get_subscription_with_jq() {

  # Get the current Cloud
  AZ_CLOUD="$(az cloud list --out tsv --query '[?isActive].name')"

  # Get the current subcription id
  AZ_PS1_SUBSCRIPTION_ID="$(cat ${AZ_PS1_CLOUD_CONFIG_FILE} | grep -A1 ${AZ_CLOUD} | grep -v ${AZ_CLOUD} | cut -d ' ' -f 3)"

  # Get the subscription name from its id
  AZ_PS1_SUBSCRIPTION=$(cat $AZ_PS1_AZURE_PROFILE_FILE | jq -r ".subscriptions[] | select(.id==\"$AZ_PS1_SUBSCRIPTION_ID\") | .name")
  if [[ -z "${AZ_PS1_SUBSCRIPTION}" ]]; then
    AZ_PS1_SUBSCRIPTION="N/A"
    return
  fi
}

_az_ps1_get_subscription_with_az() {

  AZ_PS1_SUBSCRIPTION="$(${AZ_PS1_BINARY} account show --out tsv --query 'name' 2>/dev/null)"

  if [[ -z "${AZ_PS1_SUBSCRIPTION}" ]]; then
    AZ_PS1_SUBSCRIPTION="N/A"
    return
  fi
}

_az_ps1_get_subscription() {

  if _az_ps1_binary_check "${AZ_PS1_JQ_BINARY}"; then
    _az_ps1_get_subscription_with_jq
  else
    _az_ps1_get_subscription_with_az
  fi
}

# Set az-ps1 shell defaults
_az_ps1_init

_azon_usage() {
  cat <<"EOF"
Toggle az-ps1 prompt on

Usage: azon [-g | --global] [-h | --help]

With no arguments, turn on az-ps1 status for this shell instance (default).

  -g --global  turn on az-ps1 status globally
  -h --help    print this message
EOF
}

_azoff_usage() {
  cat <<"EOF"
Toggle az-ps1 prompt off

Usage: azoff [-g | --global] [-h | --help]

With no arguments, turn off az-ps1 status for this shell instance (default).

  -g --global turn off az-ps1 status globally
  -h --help   print this message
EOF
}

azon() {
  if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
    _azon_usage
  elif [[ "${1}" == '-g' || "${1}" == '--global' ]]; then
    rm -f -- "${AZ_PS1_DISABLE_PATH}"
  elif [[ "$#" -ne 0 ]]; then
    echo -e "error: unrecognized flag ${1}\\n"
    _azon_usage
    return
  fi

  AZ_PS1_ENABLED=on
}

azoff() {
  if [[ "${1}" == '-h' || "${1}" == '--help' ]]; then
    _azoff_usage
  elif [[ "${1}" == '-g' || "${1}" == '--global' ]]; then
    mkdir -p -- "$(dirname "${AZ_PS1_DISABLE_PATH}")"
    touch -- "${AZ_PS1_DISABLE_PATH}"
  elif [[ $# -ne 0 ]]; then
    echo "error: unrecognized flag ${1}" >&2
    _azoff_usage
    return
  fi

  AZ_PS1_ENABLED=off
}

# Build our prompt
az_ps1() {
  [[ "${AZ_PS1_ENABLED}" == "off" ]] && return

  local AZ_PS1
  local AZ_PS1_RESET_COLOR="${_AZ_PS1_OPEN_ESC}${_AZ_PS1_DEFAULT_FG}${_AZ_PS1_CLOSE_ESC}"

  # Background Color
  [[ -n "${AZ_PS1_BG_COLOR}" ]] && AZ_PS1+="$(_az_ps1_color_bg ${AZ_PS1_BG_COLOR})"

  # Prefix
  [[ -n "${AZ_PS1_PREFIX}" ]] && AZ_PS1+="${AZ_PS1_PREFIX}"

  # Context
  AZ_PS1+="$(_az_ps1_color_fg $AZ_PS1_SUBSCRIPTION_COLOR)${AZ_PS1_SUBSCRIPTION}${AZ_PS1_RESET_COLOR}"

  # Suffix
  [[ -n "${AZ_PS1_SUFFIX}" ]] && AZ_PS1+="${AZ_PS1_SUFFIX}"

  # Close Background color if defined
  [[ -n "${AZ_PS1_BG_COLOR}" ]] && AZ_PS1+="${_AZ_PS1_OPEN_ESC}${_AZ_PS1_DEFAULT_BG}${_AZ_PS1_CLOSE_ESC}"

  echo "${AZ_PS1}"
}
