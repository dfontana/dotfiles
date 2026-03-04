# What branches are local but deleted in remote?
gitgone(){git branch -vv | grep "gone" | awk 'ORS=" " {print $1}';}

# What files are touched in working commit?
gittouch(){
  if [[ $# -gt 0 ]]; then
    git status -s --porcelain | grep "$1" | awk '$1 != "D" {printf "%s ", $2}'
  else
    git status -s --porcelain | awk '$1 != "D" {printf "%s ", $2}'
  fi
}

# Fetch PR comments, but honestly this is likely not needed most agents seem to know how to do this.
pr-comments() {
 gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            isResolved
            path
            line
            comments(first: 100) {
              nodes {
                author {
                  login
                }
                body
                createdAt
              }
            }
          }
        }
      }
    }
  }
' -f owner=$(gh repo view --json owner -q .owner.login) \
  -f repo=$(gh repo view --json name -q .name) \
  -F pr=$(gh pr view --json number -q .number) \
  | jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)]'
}

# Old rebase helper, jujutsu is replacing this almost entirely
function template_or_fill_first() {
  # Github CLI will just error if the template doesn't exist, where-as I want it to dynamically
  # use the first commit or the template, preferring the template if set
  if [ -n "${GH_BRANCH_TEMPLATE}" ]; then
    full_path=".github/PULL_REQUEST_TEMPLATE/$GH_BRANCH_TEMPLATE"
    if [ -f "$full_path" ]; then
      # TODO: Would be nice to fill in the first commit in the template using SED and some marker?
      #  Would require hijacking the editor command for GH to edit the temp file it creates before
      #  opening the editor. Would also require finding the first commit of the branch (cherry? merge-base?)
      #  to then copy the body out of it. Doing this against master is easy, against another branch harder.
      echo "--template $GH_BRANCH_TEMPLATE"
      return
    fi
  fi
  echo "--fill-first"
}
function gm () {
    case $* in
    # Create a branch & add to machete
    'c '* ) shift 1; git switch -c "$GH_BRANCH_PFX$@" && git machete add ;;
    # TODO: 'ci' would be a nice command to open the gitlab pipes for the active branch
    # - Need to set the env var below
    # - Need to fetch current branch & sub in below
    # - Need to test
    # Goal post: `open {instance}/{prefixSlug}/-/pipelines?page=1&scope=all&ref={branch}`
    'ci' ) shift 1;  open "$GH_GITLAB_INSTANCE/`gh repo view --json nameWithOwner | jq '.nameWithOwner'`-/pipelines?page=1&scope=all&ref={branch}"/;;
    # Cleanup gone branches from the remote
    delete ) shift 1; git fetch --prune && git branch -D `git branch -vv | grep "gone" | awk 'ORS=" " {print $1}';` ;;
    # Add all tracked changes to the last commit without editing
    m ) ;&
    'm '* ) shift 1; git commit --amend --no-edit "$@" && git machete traverse --no-push --no-push-untracked -y --start-from=here --return-to=here ;;
    # TODO Move head of branch to another spot by selectively chosing where to place it
    move ) shift 1; echo 'todo' ;;
    # Interactive checkout of a branch
    switch ) shift 1; git branch -v --sort=-committerdate | fzf --layout=reverse-list --bind "enter:execute(git checkout {1})+accept-non-empty" ;;
    'switch '* ) shift 1;  git checkout "$1" ;;
    # Edit the contents of a PR
    'pr edit'* ) shift 2; gh pr edit "$@" ;;
    # Open active branch's PR
    pr ) ;&
    'pr '* ) shift 1; gh pr view --web "$@" ;;
    # Fetch & drop stale branches from start, update each in the tree. This will rebase on master too.
    # Mode 'exact' is needed to catch squash merges, as I found the 'simple' default did not.
    sync ) ;&
    'sync '* ) shift 1; git machete traverse -Wn --squash-merge-detection=exact "$@"; gm delete ;;
    # Push & Create or Update PR. If a PR already exists it won't be made again.
    # TODO: ... but if it already exists it also won't be pushed. Perhaps push then create? See if machete can help with this given it may or may not require a force-with-lease.
    s ) ;&
    's '* ) shift 1; gh pr create -e $(template_or_fill_first) "$@" ;;
    # Push all branches in the stack from the root; this does not create PRs to minimize impact.
    ss ) ;&
    'ss '* ) shift 1; git machete traverse -yw --return-to=here ;;
    # Default forward to machete
    * ) git machete "$@" ;;
    esac
}

