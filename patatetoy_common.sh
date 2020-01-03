# vim ft=bash
# This file define common function for zsh & bash prompt
#
# It define for prompts:
# - symbol/colors values
# - git & time functions
# - behaviors
#
# Git functions are extracted from:
# Bring a light and modified version of git-prompt.sh functions from Shawn O. Pearce <spearce@spearce.org>
# https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh

# Config
export PATATETOY_CMD_MAX_EXEC_TIME=${PATATETOY_CMD_MAX_EXEC_TIME:-5}
export PATATETOY_FORCE_DISPLAY_USERNAME=${PATATETOY_FORCE_DISPLAY_USERNAME:-0}
export PATATETOY_GIT_PULL=${PATATETOY_GIT_PULL:-1}
export PATATETOY_GIT_STASH_CHECK=${PATATETOY_GIT_STASH_CHECK:-1}
export PATATETOY_GIT_UNTRACKED_DIRTY=${PATATETOY_GIT_UNTRACKED_DIRTY:-1}

# Symbols
export PATATETOY_GIT_DIRTY_SYMBOL=${PATATETOY_GIT_DIRTY_SYMBOL:-'✗'}
export PATATETOY_GIT_DOWN_ARROW=${PATATETOY_GIT_DOWN_ARROW:-⬇}
export PATATETOY_GIT_STASH_SYMBOL=${PATATETOY_GIT_STASH_SYMBOL:-"ⵢ"}
export PATATETOY_GIT_UP_ARROW=${PATATETOY_GIT_UP_ARROW:-⬆}
export PATATETOY_PROMPT_SYMBOL=${PATATETOY_PROMPT_SYMBOL:-❯}
export PATATETOY_ROOT_SYMBOL=${PATATATETOY_ROOT_SYMBOL:-"✦"}

# Colors
export PATATETOY_CURSOR_COLOR_KO=${PATATETOY_CURSOR_COLOR_KO:-red}
export PATATETOY_CURSOR_COLOR_OK=${PATATETOY_CURSOR_COLOR_OK:-yellow}
export PATATETOY_GIT_ARROW_COLOR=${PATATETOY_GIT_ARROW_COLOR:-yellow}
export PATATETOY_GIT_BRANCH_COLOR=${PATATETOY_GIT_BRANCH_COLOR:-darkgrey}
export PATATETOY_GIT_DIRTY_SYMBOL_COLOR=${PATATETOY_GIT_DIRTY_SYMBOL_COLOR:-darkgrey}
export PATATETOY_GIT_STASH_SYMBOL_COLOR=${PATATETOY_GIT_STASH_SYMBOL_COLOR:-cyan}
export PATATETOY_PATH_COLOR=${PATATETOY_PATH_COLOR:-blue}
export PATATETOY_ROOT_SYMBOL_COLOR=${PATATETOY_ROOT_SYMBOL_COLOR:-red}
export PATATETOY_USERNAME_COLOR=${PATATETOY_USERNAME_COLOR:-green}
export PATATETOY_VIRTUALENV_COLOR=${PATATETOY_VIRTUALENV_COLOR:-darkgrey}

# Helper function to read the first line of a file into a variable.
# __git_eread requires 2 arguments, the file path and the name of the
# variable, in that order.
# shellcheck disable=SC2162
__git_eread() {
  test -r "$1" && IFS=$'\r\n' read "$2" <"$1"
}

# see if a cherry-pick or revert is in progress, if the user has committed a
# conflict resolution with 'git commit' in the middle of a sequence of picks or
# reverts then CHERRY_PICK_HEAD/REVERT_HEAD will not exist so we have to read
# the todo file.
__git_sequencer_status() {
  local todo
  if test -f "$g/CHERRY_PICK_HEAD"; then
    r="|CHERRY-PICKING"
    return 0
  elif test -f "$g/REVERT_HEAD"; then
    r="|REVERTING"
    return 0
  elif __git_eread "$g/sequencer/todo" todo; then
    case "$todo" in
      p[\ \	] | pick[\ \	]*)
        r="|CHERRY-PICKING"
        return 0
        ;;
      revert[\ \	]*)
        r="|REVERTING"
        return 0
        ;;
    esac
  fi
  return 1
}

# Get git repo informations
#
# Exported vars:
# - patatetoy_vcs_legacy - don't use the '--count' option available in recent versions of git-rev-list
# - patatetoy_git_stash - contain stash symbol if some stash exists
# - patatetoy_git_branch - contain the name of the current branch
# - patatetoy_git_action - contain action such as REBASE/CHERRY-PICK
# - patatetoy_git_inside_worktree - if in git repo
#
_patatetoy_vcs_info() {
  export patatetoy_vcs_legacy
  export patatetoy_git_stash
  export patatetoy_git_branch
  export patatetoy_git_action
  export patatetoy_git_inside_worktree

  # preserve exit status
  local exit=$?

  [ -z "${ZSH_VERSION-}" ] || [[ -o PROMPT_SUBST ]]
  [ -z "${BASH_VERSION-}" ] || shopt -q promptvars

  local repo_info rev_parse_exit_code
  local short_sha

  repo_info="$(git rev-parse --git-dir --is-inside-git-dir \
    --is-bare-repository --is-inside-work-tree \
    --short HEAD 2>/dev/null)"
  rev_parse_exit_code="$?"

  if [ -z "$repo_info" ]; then
    return $exit
  fi

  if [ "$rev_parse_exit_code" = "0" ]; then
    short_sha="${repo_info##*$'\n'}"
    repo_info="${repo_info%$'\n'*}"
  fi
  patatetoy_git_inside_worktree="${repo_info##*$'\n'}"
  repo_info="${repo_info%$'\n'*}"
  repo_info="${repo_info%$'\n'*}"
  g="${repo_info%$'\n'*}"

  # Stash
  if [[ "$PATATETOY_GIT_STASH_CHECK" == "1" && $(git stash list 2>/dev/null | tail -n1) != "" ]]; then
    patatetoy_git_stash=$PATATETOY_GIT_STASH_SYMBOL
  fi

  # Branch / Action
  local r=""
  local b=""
  local step=""
  local total=""

  if [ -d "$g/rebase-merge" ]; then
    __git_eread "$g/rebase-merge/head-name" b
    __git_eread "$g/rebase-merge/msgnum" step
    __git_eread "$g/rebase-merge/end" total
    if [ -f "$g/rebase-merge/interactive" ]; then
      r="|REBASE-i"
    else
      r="|REBASE-m"
    fi
  else
    if [ -d "$g/rebase-apply" ]; then
      __git_eread "$g/rebase-apply/next" step
      __git_eread "$g/rebase-apply/last" total
      if [ -f "$g/rebase-apply/rebasing" ]; then
        __git_eread "$g/rebase-apply/head-name" b
        r="|REBASE"
      elif [ -f "$g/rebase-apply/applying" ]; then
        r="|AM"
      else
        r="|AM/REBASE"
      fi
    elif [ -f "$g/MERGE_HEAD" ]; then
      r="|MERGING"
    elif __git_sequencer_status; then
      :
    elif [ -f "$g/BISECT_LOG" ]; then
      r="|BISECTING"
    fi
    if [ -n "$b" ]; then
      :
    elif [ -h "$g/HEAD" ]; then
      # symlink symbolic ref
      b="$(git symbolic-ref HEAD 2>/dev/null)"
    else
      local head=""
      if ! __git_eread "$g/HEAD" head; then
        return $exit
      fi
      # is it a symbolic ref?
      b="${head#ref: }"
      if [ "$head" = "$b" ]; then
        b="$(
          case "${GIT_PS1_DESCRIBE_STYLE-}" in
            contains)
              git describe --contains HEAD
              ;;
            branch)
              git describe --contains --all HEAD
              ;;
            tag)
              git describe --tags HEAD
              ;;
            describe)
              git describe HEAD
              ;;
            *)
              git describe --tags --exact-match HEAD
              ;;
          esac 2>/dev/null
        )" ||
          b="$short_sha..."
        b="($b)"
      fi
    fi
  fi
  if [ -n "$step" ] && [ -n "$total" ]; then
    r="$r $step/$total "
  fi
  b=${b##refs/heads/}
  patatetoy_git_branch="${b}"
  patatetoy_git_action="${r}"
}

# Detect changes with upstreams
#
# Exported vars:
# - patatetoy_git_upstream - git arrow symbols
#
_patatetoy_vcs_upstream() {
  export patatetoy_git_upstream=
  local count
  local p
  # Find how many commits we are ahead/behind our upstream
  count=$(git rev-list --count --left-right "@{u}"...HEAD 2>/dev/null)
  case "$count" in
    "") # no upstream
      p="" ;;
    "0	0") # equal to upstream
      p="" ;;
    "0	"*) # ahead of upstream
      p=$PATATETOY_GIT_UP_ARROW ;;
    *"	0") # behind upstream
      p=$PATATETOY_GIT_DOWN_ARROW ;;
    *) # diverged from upstream
      p=${PATATETOY_GIT_DOWN_ARROW}${PATATETOY_GIT_UP_ARROW} ;;
  esac
  patatetoy_git_upstream="$p"
}

# Check if repo is dirty
# Return check command code
_patatetoy_vcs_dirty() {
  if [[ "$PATATETOY_GIT_UNTRACKED_DIRTY" == "0" ]]; then
    command git diff --no-ext-diff --quiet --exit-code
  else
    test -z "$(command git status --porcelain --ignore-submodules -unormal)"
  fi
  return $?
}

# Calculate elapsed time in human readable format
# Exported vars:
# - patatetoy_cmd_human_time - elapsed time in seconds, minutes, hours...
#
_patatetoy_cmd_exec_time() {
  local elapsed=$1
  export patatetoy_human_exec_time

  if [[ $elapsed -gt $PATATETOY_CMD_MAX_EXEC_TIME ]]; then
    local human="" total_seconds=$1
    local days=$((total_seconds / 60 / 60 / 24))
    local hours=$((total_seconds / 60 / 60 % 24))
    local minutes=$((total_seconds / 60 % 60))
    local seconds=$((total_seconds % 60))
    ((days > 0)) && human+="${days}d "
    ((hours > 0)) && human+="${hours}h "
    ((minutes > 0)) && human+="${minutes}m "
    human+="${seconds}s"
    patatetoy_human_exec_time="${human}"
  fi
}
