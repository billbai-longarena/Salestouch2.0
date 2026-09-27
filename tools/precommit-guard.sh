#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# SaleTouch 2.0 · 公开代码仓库的提交守卫
#
# 设计前提：本仓库**只放纯代码**。设计文档、调研、工作笔记、业务知识
# 一律在 ../salestouch2.0DevelopWorkspace 与 ../salestouch2.0Plugin。
#
# 因此本脚本的规则是「文档黑名单」——不依赖任何业务词汇，
# 所以本文件本身可以安全地公开。
#
# 安装：bash tools/precommit-guard.sh --install
# 检查：bash tools/precommit-guard.sh --check-staged
#
# 可选：若本机存在外部敏感词表（由私有工作区维护），会自动加载做内容扫描。
#   查找顺序：$SALESTOUCH_GUARD_TERMS
#             → ../salestouch2.0DevelopWorkspace/tools/guard-terms.txt
#             → ~/.salestouch/guard-terms.txt
#   找不到时仅做路径/文件名检查（普通贡献者即为此情形，属预期）。
# ─────────────────────────────────────────────────────────────
set -uo pipefail

GIT="git -c core.quotePath=false"
THRESHOLD=3
TERMS_FILE=""

# ── ① 受保护路径：这些目录属于「非代码内容」 ──
PROTECTED_PATHS=(
  '^docs/'
  '^design/'
  '^research/'
  '^notes/'
  '^drafts?/'
  '^private/'
  '^\.obsidian/'
  'salestouch2\.0Plugin'
  'salestouch2\.0DevelopWorkspace'
  '^calibration/'
  '^tenant-maps/'
  '^customer-data/'
  '^analytics-export/'
  '^packs/'
)

# ── ② 受保护文件名模式 ──
PROTECTED_NAMES=(
  'knowhow.?pack'
  'knowledge.?pack'
  'promptpack'
  'evalpack'
  'templatepack'
  'customer.?map'
  'calibration'
  '\.design\.md$'
  '(^|/)(设计|方案|调研|笔记|草稿)'
)

# ── ③ 内容敏感词：从外部加载（词表本身不在本仓库中） ──
load_terms() {
  local candidates=(
    "${SALESTOUCH_GUARD_TERMS:-}"
    "../salestouch2.0DevelopWorkspace/tools/guard-terms.txt"
    "$HOME/.salestouch/guard-terms.txt"
  )
  local c
  for c in "${candidates[@]}"; do
    if [ -n "$c" ] && [ -f "$c" ]; then TERMS_FILE="$c"; return 0; fi
  done
  return 1
}

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }

staged_files_z() { $GIT diff --cached --name-only -z --diff-filter=ACM 2>/dev/null; }

check_staged() {
  local violations=0

  if [ "${ALLOW_DESIGN:-0}" = "1" ]; then
    yellow "⚠️  ALLOW_DESIGN=1 —— 已跳过检查（请确认这是有意的）"
    return 0
  fi

  # ── 路径与文件名 ──
  local f pat name
  while IFS= read -r -d '' f; do
    [ -z "$f" ] && continue
    for pat in "${PROTECTED_PATHS[@]}"; do
      if printf '%s' "$f" | grep -qE "$pat" 2>/dev/null; then
        red "🚫 拒绝提交（受保护路径）: $f"
        violations=$((violations+1)); continue 2
      fi
    done
    for name in "${PROTECTED_NAMES[@]}"; do
      if printf '%s' "$f" | grep -qiE "$name" 2>/dev/null; then
        red "🚫 拒绝提交（文件名命中受保护模式）: $f"
        violations=$((violations+1)); continue 2
      fi
    done
  done < <(staged_files_z)

  # ── 内容敏感词（仅当外部词表存在时） ──
  if load_terms; then
    local -a terms=()
    while IFS= read -r line; do
      case "$line" in ''|'#'*) continue;; esac
      terms+=("$line")
    done < "$TERMS_FILE"

    local size hits hitlist term
    while IFS= read -r -d '' f; do
      [ -z "$f" ] && continue
      [ -f "$f" ] || continue
      file --mime-encoding "$f" 2>/dev/null | grep -qiE 'utf-8|us-ascii|iso-8859' || continue
      size=$(wc -c < "$f" 2>/dev/null || echo 0)
      [ "$size" -gt 1048576 ] && continue

      hits=0; hitlist=""
      for term in "${terms[@]}"; do
        if $GIT diff --cached -U0 -- "$f" 2>/dev/null | grep '^+' | grep -qF "$term"; then
          hits=$((hits+1)); hitlist="$hitlist $term"
        fi
      done
      if [ "$hits" -ge "$THRESHOLD" ]; then
        red "🚫 拒绝提交（内容命中 $hits 个敏感词）: $f"
        yellow "     命中:$hitlist"
        violations=$((violations+1))
      elif [ "$hits" -gt 0 ]; then
        yellow "⚠️  $f 命中 $hits 个敏感词（阈值 ${THRESHOLD}），已放行"
      fi
    done < <(staged_files_z)
  fi

  if [ "$violations" -gt 0 ]; then
    echo
    red "═══════════════════════════════════════════════"
    red " 提交被阻止：$violations 处内容不属于本仓库"
    red "═══════════════════════════════════════════════"
    echo
    yellow "本仓库只放纯代码。以下内容应放在别处："
    yellow "  · 设计文档 / 调研 / 笔记 → ../salestouch2.0DevelopWorkspace/"
    yellow "  · 业务知识 / 方法论文档   → ../salestouch2.0Plugin/"
    yellow "  · 生成的知识包制品        → ../salestouch2.0Plugin/packs/"
    echo
    yellow "移除：  git restore --staged <file>"
    yellow "放行：  ALLOW_DESIGN=1 git commit ..."
    echo
    exit 1
  fi

  green "✅ 代码仓库检查通过"
  return 0
}

install_hook() {
  [ -d ".git" ] || { red "不是 git 仓库，请先 git init"; exit 1; }
  mkdir -p .git/hooks
  cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
exec bash tools/precommit-guard.sh --check-staged
HOOK
  chmod +x .git/hooks/pre-commit
  green "✅ pre-commit 钩子已安装"

  cat > .git/hooks/commit-msg <<'HOOK'
#!/usr/bin/env bash
# 提交信息只应描述代码改动，不应描述业务设计
msg="$1"; hits=0
tf="../salestouch2.0DevelopWorkspace/tools/guard-terms.txt"
if [ -f "$tf" ]; then
  while IFS= read -r t; do
    case "$t" in ''|'#'*) continue;; esac
    grep -qF "$t" "$msg" 2>/dev/null && hits=$((hits+1))
  done < "$tf"
fi
if [ "$hits" -ge 2 ] && [ "${ALLOW_DESIGN:-0}" != "1" ]; then
  echo "🚫 提交信息疑似包含业务设计内容，请只描述代码改动。"
  exit 1
fi
HOOK
  chmod +x .git/hooks/commit-msg
  green "✅ commit-msg 钩子已安装"

  if load_terms; then
    green "✅ 已加载外部敏感词表: $TERMS_FILE"
  else
    yellow "ℹ️  未找到外部敏感词表（普通贡献者属正常）；仅启用路径与文件名检查。"
  fi
}

case "${1:-}" in
  --install)      install_hook ;;
  --check-staged) check_staged ;;
  *) echo "用法: bash tools/precommit-guard.sh [--install|--check-staged]"; exit 1 ;;
esac
