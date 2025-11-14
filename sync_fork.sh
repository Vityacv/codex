#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./sync_fork.sh [options]

Synchronizes a fork by rebasing a branch onto an upstream remote and pushing back
to the origin remote with --force-with-lease.

Options:
  -d, --dir <path>           Repository to operate on (default: current dir)
  -b, --branch <name>        Branch to sync (default: main)
  -u, --upstream <name>      Upstream remote name (default: upstream)
  -U, --upstream-url <url>   Remote URL to add if the upstream remote is missing
  -o, --origin <name>        Origin remote name (default: origin)
  -h, --help                 Show this help text

Examples:
  ./sync_fork.sh
  ./sync_fork.sh --branch develop --upstream upstream --origin origin
  ./sync_fork.sh -d ../other-repo -b release -u upstream -U https://github.com/org/repo.git
EOF
}

REPO_DIR="."
BRANCH="main"
UPSTREAM_REMOTE="upstream"
ORIGIN_REMOTE="origin"
UPSTREAM_URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dir)
            [[ $# -lt 2 ]] && { usage; exit 1; }
            REPO_DIR="$2"
            shift 2
            ;;
        -b|--branch)
            [[ $# -lt 2 ]] && { usage; exit 1; }
            BRANCH="$2"
            shift 2
            ;;
        -u|--upstream)
            [[ $# -lt 2 ]] && { usage; exit 1; }
            UPSTREAM_REMOTE="$2"
            shift 2
            ;;
        -U|--upstream-url)
            [[ $# -lt 2 ]] && { usage; exit 1; }
            UPSTREAM_URL="$2"
            shift 2
            ;;
        -o|--origin)
            [[ $# -lt 2 ]] && { usage; exit 1; }
            ORIGIN_REMOTE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ ! -d "${REPO_DIR}" ]]; then
    echo "error: directory '${REPO_DIR}' does not exist." >&2
    exit 1
fi

cd "${REPO_DIR}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: '${REPO_DIR}' is not a git repository." >&2
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

if ! git remote get-url "${UPSTREAM_REMOTE}" >/dev/null 2>&1; then
    if [[ -n "${UPSTREAM_URL}" ]]; then
        echo "Adding remote '${UPSTREAM_REMOTE}' -> ${UPSTREAM_URL}"
        git remote add "${UPSTREAM_REMOTE}" "${UPSTREAM_URL}"
    else
        cat <<EOF >&2
error: remote '${UPSTREAM_REMOTE}' does not exist.
Add it with:
  git remote add ${UPSTREAM_REMOTE} <upstream-url>
or re-run this script with --upstream-url <url>.
EOF
        exit 1
    fi
fi

if ! git remote get-url "${ORIGIN_REMOTE}" >/dev/null 2>&1; then
    echo "error: remote '${ORIGIN_REMOTE}' is missing; cannot push." >&2
    exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "${CURRENT_BRANCH}" != "${BRANCH}" ]]; then
    echo "Checking out ${BRANCH} (was on ${CURRENT_BRANCH})..."
    git checkout "${BRANCH}"
fi

echo "Fetching ${UPSTREAM_REMOTE}..."
git fetch "${UPSTREAM_REMOTE}"

echo "Rebasing ${BRANCH} onto ${UPSTREAM_REMOTE}/${BRANCH} with --autostash..."
git pull --rebase --autostash "${UPSTREAM_REMOTE}" "${BRANCH}"

echo "Pushing ${BRANCH} to ${ORIGIN_REMOTE} with --force-with-lease..."
git push "${ORIGIN_REMOTE}" "${BRANCH}" --force-with-lease

echo "Sync complete for ${REPO_ROOT} (${BRANCH})."
