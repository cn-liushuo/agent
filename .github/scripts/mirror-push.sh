#!/usr/bin/env bash
# 将当前仓库按 commit 分批镜像推送到指定 SSH 远端（Gitee / GitCode）。
# 从最早提交起每批固定数量推进，支持从远端已有 tip 续传；最后对齐其余分支与 tags。
set -euo pipefail

REMOTE_URL="${1:?用法: mirror-push.sh <ssh-git-url>}"
BATCH_SIZE="${BATCH_SIZE:-5}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-5}"

# 带退避的 git push，应对 Broken pipe / hung up；参数原样传给 git push
push_with_retry() {
  local attempt=1
  while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
    echo ">>> Push attempt ${attempt}/${MAX_ATTEMPTS}: $*"
    if git push "${REMOTE_URL}" "$@"; then
      echo ">>> Push ok: $*"
      return 0
    fi
    if [ "$attempt" -eq "$MAX_ATTEMPTS" ]; then
      echo ">>> Push failed after ${MAX_ATTEMPTS} attempts: $*"
      return 1
    fi
    local sleep_seconds=$((attempt * 30))
    echo ">>> Interrupted, retry in ${sleep_seconds}s..."
    sleep "${sleep_seconds}"
    attempt=$((attempt + 1))
  done
}

# 单分支：从 origin/<branch> 历史起点按 BATCH_SIZE 个 commit 推进到 tip
sync_branch_by_commits() {
  local branch="$1"
  local local_ref="refs/remotes/origin/${branch}"

  if ! git show-ref --verify --quiet "${local_ref}"; then
    echo ">>> Skip missing branch: ${branch}"
    return 0
  fi

  local tip
  tip="$(git rev-parse "${local_ref}")"

  local commits=()
  # 从旧到新，保证每批都是快进，远端可逐步落盘对象
  mapfile -t commits < <(git rev-list --reverse "${local_ref}")
  local total="${#commits[@]}"
  if [ "${total}" -eq 0 ]; then
    echo ">>> Empty history: ${branch}"
    return 0
  fi

  local remote_sha=""
  remote_sha="$(git ls-remote "${REMOTE_URL}" "refs/heads/${branch}" | awk '{print $1}')"

  local start=0
  if [ -n "${remote_sha}" ]; then
    if [ "${remote_sha}" = "${tip}" ]; then
      echo ">>> Branch ${branch} already up to date (${tip})"
      return 0
    fi

    local found=0
    local i
    for i in "${!commits[@]}"; do
      if [ "${commits[$i]}" = "${remote_sha}" ]; then
        start=$((i + 1))
        found=1
        break
      fi
    done

    # 远端 tip 不在本地历史：强制一次对齐（少见，例如误推）
    if [ "${found}" -eq 0 ]; then
      echo ">>> Remote ${branch} tip not in local history, force align tip"
      push_with_retry "+${tip}:refs/heads/${branch}"
      return 0
    fi
  fi

  echo ">>> Sync ${branch}: total=${total}, resume_index=${start}, batch=${BATCH_SIZE}"

  local end sha
  local i
  for ((i = start; i < total; i += BATCH_SIZE)); do
    end=$((i + BATCH_SIZE - 1))
    if [ "${end}" -ge "${total}" ]; then
      end=$((total - 1))
    fi
    sha="${commits[$end]}"
    echo ">>> ${branch} commits $((i + 1))-$((end + 1))/${total} -> ${sha}"
    push_with_retry "${sha}:refs/heads/${branch}"
  done
}

echo ">>> Mirror start -> ${REMOTE_URL} (batch=${BATCH_SIZE})"

# 同步 origin 下全部分支（含 main/master）
mapfile -t branches < <(
  git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/origin \
    | grep -vx 'HEAD' \
    | sort -u
)

if [ "${#branches[@]}" -eq 0 ]; then
  echo ">>> No origin branches found"
  exit 1
fi

for branch in "${branches[@]}"; do
  sync_branch_by_commits "${branch}"
done

# tags：对象多已随分支到位，单独对齐引用
if [ -n "$(git tag -l)" ]; then
  echo ">>> Sync tags"
  push_with_retry --tags
else
  echo ">>> No tags to sync"
fi

# 清理远端多余分支（与 origin 对齐）；对象已齐时通常很快
echo ">>> Prune remote branches to match origin"
push_with_retry --prune "+refs/remotes/origin/*:refs/heads/*"

echo ">>> Mirror done -> ${REMOTE_URL}"
