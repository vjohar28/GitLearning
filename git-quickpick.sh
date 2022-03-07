#!/bin/bash

# Author: Thomas Berezansky <tsbere@mvlc.org>
# Author: Jason Stephenson <jason@sigio.com>
#
# Feel free to use and to share this script in anyway you like.

# This script is intended as a shortcut for the git cherry-pick
# command when you have several commits that you want to cherry-pick
# into your local branch from another branch.  It often results in a
# cleaner commit history than simply doing a git merge.

# It can be run in two ways and either method takes an optional
# parameter, -s.  If provided the -s parameter will add your git
# signature to each incoming commit as they are cherry-picked.  This
# is a handy way to sign off on someone else's commits in bulk when
# your project has a policy of requiring sign offs on anything going
# into the main git repository.  If you supply the -s parameter, it
# should come before any branch or commit arguments on the command
# line.

# The simpler way to run this script is to simply supply the branch
# name whose commits you want to cherry-pick into your current branch.
# For instance, if you want to cherry-pick the commits from branch
# `bar' of remote `foo' that do not exist in your current branch you
# would use the following:
#
# quickpick foo/bar
#
# or
#
# quickpick -s foo/bar
#
# to include your sign off.

# The second way to use this script is to specify two branches: the
# base and the feature.  In this case the base is the branch, other
# than the current branch, to compare with the feature branch.  This
# mode will use git cherry to pull out those commit in feature branch
# that do not exist in base.  This is useful if you're trying to merge
# commits into a branch that does not share a common history with
# feature branch.  Let's say that our branch, local, is based on a
# fork of the master at some point in the past, and feature branch is
# based on the current master branch.  We want to pull the new commits
# from feature into our local branch without getting the commits
# common to the master and feature branch that are not in our local
# branch.  We do that by running this command in a checkout of our
# local branch:
#
# quickpick master feature

# Should you run into a conflict while cherry-picking, you would
# resolve in the usual way.  Should you still have outstanding commits
# left to pull in, you may pickup where you left off by using the
# special argument `--continue.'  Even if you believe that your
# conflict occurred in the final cherry-pick, it won't hurt to use the
# --continue argument as a precaution against missing any commits.
# The script keeps track of the commits that have been cherry-picked
# as it runs, and so it would be safe to run --continue when there are
# none left.

if [ "$1" == "-s" ]; then
    SIGN="-s"
    shift
else
    SIGN=""
fi

START=${1:-'FAIL'}
END=${2:-'CHERRY'}
if [ "$1" == 'FAIL' ]; then
    echo "NEED SOURCE BRANCH"
    exit 1;
fi
if [ "$START" == '--continue' ]; then
    COMMITS=`cat ~/.git-cherrypick-resume-commits`
    SIGN=`cat ~/.git-cherrypick-resume-sign`
else
    if [ "$END" == 'CHERRY' ]; then
        END=$START
        START='HEAD'
    fi
    COMMITS=`git cherry $START $END | grep ^+ | cut -f2 -d' '`
fi
if [ "$SIGN" != "-s" ]; then
    SIGN=''
fi
for commit in $COMMITS
do
    COMMITS=`echo $COMMITS | sed -e "s/.*$commit\s*//"`
    git cherry-pick $SIGN $commit
    if [ $? -ne 0 ]; then
        echo $COMMITS > ~/.git-cherrypick-resume-commits
        echo "$SIGN" > ~/.git-cherrypick-resume-sign
        exit 1
    fi
done
rm -f ~/.git-cherrypick-resume-commits ~/.git-cherrypick-resume-sign
exit 0
