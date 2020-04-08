#!/usr/bin/env bash
# Patatetoy
# by Maxime Loliée
# https://github.com/loliee/patatetoy

# shellcheck disable=SC1090
PATATETOY_SRC_DIR=${PATATETOY_SRC_DIR:-"${HOME}/.patatetoy"}
if [[ -f "${PATATETOY_SRC_DIR}/patatetoy_common.sh" ]]; then
  . "${PATATETOY_SRC_DIR}/patatetoy_common.sh"
else
  echo >&2 "Cannot load patatetoy libraries from: ${PATATETOY_SRC_DIR}"
fi

export c='\[\e[0m\]'
export darkgrey='\[\e[0;90m\]'
export red='\[\e[0;31m\]'
export green='\[\e[0;32m\]'
export yellow='\[\e[0;33m\]'
export blue='\[\e[0;34m\]'
export magenta='\[\e[0;35m\]'
export cyan='\[\e[0;36m\]'
export grey='\[\e[0;30m\]'
export white='\[\e[0;97m\]'

PROMPT_COMMAND=__prompt_command

__timer_start() {
  timer=${timer:-$SECONDS}
}

__timer_stop() {
  elapsed=$((SECONDS - timer))
  unset timer
}

__virtualenv_info() {
  [ "$VIRTUAL_ENV" ] && basename "$VIRTUAL_ENV"
}

__patatetoy_collapse_pwd() {
  p=$(pwd | sed -e "s,^$HOME,~,")
  if [[ ${#p} -gt 90 ]]; then
    echo "…${p:(-90)}"
  else
    echo "$p"
  fi
}

__prompt_command() {
  local exit_code=$?
  local virtualenv
  export patatetoy_git_branch=
  export patatetoy_git_stash=
  export patatetoy_git_upstream=
  export patatetoy_git_action=
  export patatetoy_human_exec_time=
  export patatetoy_git_inside_worktree=

  # Manage command time execution.
  __timer_stop
  _patatetoy_cmd_exec_time $elapsed

  # Init prompt sequence
  PS1="\n"
  if [[ "$SSH_CONNECTION" != '' ]] || [[ $PATATETOY_FORCE_DISPLAY_USERNAME == 1 ]]; then
    PS1+="${!PATATETOY_USERNAME_COLOR}\u@\h${c} "
  fi

  # show red star if root
  if [[ $UID -eq 0 ]]; then
    PS1+="${!PATATETOY_ROOT_SYMBOL_COLOR}${PATATETOY_ROOT_SYMBOL}${c} "
  fi

  PS1+="${!PATATETOY_PATH_COLOR}$(__patatetoy_collapse_pwd)${c}"

  _patatetoy_vcs_info

  if [[ $patatetoy_git_inside_worktree == true ]]; then
    # Check upstream
    if [[ $PATATETOY_GIT_PULL == 1 ]]; then
      _patatetoy_vcs_upstream
    fi

    if _patatetoy_vcs_dirty; then
      prompt_patatetoy_git_dirty=""
    else
      prompt_patatetoy_git_dirty="$PATATETOY_GIT_DIRTY_SYMBOL"
    fi

    PS1+="${!PATATETOY_GIT_BRANCH_COLOR} ${patatetoy_git_branch}${c}"
    if [[ -n ${patatetoy_git_action} ]]; then
      PS1+="${!PATATETOY_GIT_BRANCH_COLOR}${patatetoy_git_action}${c}"
    fi
    PS1+="${!PATATETOY_GIT_DIRTY_SYMBOL_COLOR}${prompt_patatetoy_git_dirty}${c}"
    PS1+="${!PATATETOY_GIT_STASH_SYMBOL_COLOR}${patatetoy_git_stash}${c}"

    if [[ -n $patatetoy_git_upstream ]]; then
      PS1+="${!PATATETOY_GIT_ARROW_COLOR} ${patatetoy_git_upstream}${c}"
    fi
  fi

  if [[ -n $patatetoy_human_exec_time ]]; then
    PS1+="${yellow} ${patatetoy_human_exec_time}${c}"
  fi

  virtualenv=$(__virtualenv_info)
  if [[ -n ${virtualenv} ]]; then
    PS1+="\n${!PATATETOY_VIRTUALENV_COLOR}${virtualenv}${c} "
  else
    PS1+="\n"
  fi

  # check previous command result
  if [[ $exit_code -ne 0 ]]; then
    PS1+="${!PATATETOY_CURSOR_COLOR_KO}"
  else
    PS1+="${!PATATETOY_CURSOR_COLOR_OK}"
  fi

  PS1+="${PATATETOY_PROMPT_SYMBOL} ${c}"

  export PS1
}

# Set timer
trap '__timer_start' DEBUG
export PROMPT_COMMAND
