#!/usr/bin/env zsh
# Print zsh's own completions for a command line, one per line.
#
#   zsh zsh_complete.zsh 'git sw'      ->  switch  ...
#
# Used by lua/utils/shell.lua for <Tab> in the runner's command prompt. Runs
# a hidden interactive zsh in a pseudo-terminal (zsh/zpty), types the line
# plus <Tab>, and captures what the completion system would offer: compadd
# is wrapped to print the matches instead of inserting them. Technique from
# zsh-capture-completion (Valodim, MIT).
#
# $FPATH (set by the caller to the user's interactive fpath) decides which
# completion functions exist; $ZCOMPDUMP is the compinit cache file. Runs in
# the caller's cwd, so file matches are relative to it. Gives up after
# $ZSH_COMPLETE_TIMEOUT seconds (default 2) and exits 3.

zmodload zsh/zpty || { print -u2 'zsh_complete: no zsh/zpty module'; exit 1 }
zmodload zsh/zselect
typeset -F SECONDS=0
float deadline=${ZSH_COMPLETE_TIMEOUT:-2}

zpty z zsh -f -i

local line
setopt rcquotes
() {
	zpty -w z source $1
	repeat 4; do
		zpty -r z line
		[[ $line == ok* ]] && return
	done
	print -u2 'zsh_complete: init failed'
	zpty -d z
	exit 2
} =( <<< '
PROMPT=
RPROMPT=
[[ -n $FPATH ]] && fpath=( ${(s.:.)FPATH} )
autoload -U compinit && compinit -C -d "${ZCOMPDUMP:-${TMPDIR:-/tmp}/zcompdump-capture}"

# One match per line, no grouping, menus or tab insertion.
zstyle ":completion:*" list-grouped false
zstyle ":completion:*" insert-tab false
zstyle ":completion:*" list-separator ""
zstyle ":completion:*" menu no

compadd () {
	# -O/-A/-D only fill arrays for the caller: not real matches, pass through.
	if [[ ${@[1,(i)(-|--)]} == *-(O|A|D)\ * ]]; then
		builtin compadd "$@"
		return $?
	fi

	typeset -a __hits
	builtin compadd -A __hits "$@"

	setopt localoptions norcexpandparam extendedglob
	typeset -A apre hpre hsuf asuf
	zparseopts -E P:=apre p:=hpre S:=asuf s:=hsuf

	# Folder matches from file completion get a trailing slash.
	integer dirsuf=0
	if [[ -z $hsuf && "${${@//-default-/}% -# *}" == *-[[:alnum:]]#f* ]]; then
		dirsuf=1
	fi

	[[ -n $__hits ]] || return
	local dsuf
	for i in {1..$#__hits}; do
		(( dirsuf )) && [[ -d $__hits[$i] ]] && dsuf=/ || dsuf=
		print -r -- $IPREFIX$apre$hpre$__hits[$i]$dsuf$hsuf$asuf
	done
}

# A NUL line before and after the matches, then exit.
null-line () { print -r -- $'"'"'\0'"'"' }
compprefuncs=( null-line )
comppostfuncs=( null-line exit )

echo ok')

zpty -w z "$*"$'\t'

# Matches come between two NUL lines. Poll with a deadline: a completion
# function that never finishes must not hang the caller.
integer tog=0
while (( SECONDS < deadline )); do
	if ! zpty -r -t z line; then
		zselect -t 1 # 10ms
		continue
	fi
	if [[ $line == *$'\0\r'* ]]; then
		(( tog++ )) && { zpty -d z; exit 0 }
		continue
	fi
	(( tog )) && print -r -- ${${line%$'\n'}%$'\r'}
done
zpty -d z
exit 3
