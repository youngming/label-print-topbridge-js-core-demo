#!/usr/bin/env bash
set -euo pipefail

# Cloudflare Pages 部署脚本（Direct Upload）
# 用法：
#   bash scripts/deploy.sh          # 完整部署
#   bash scripts/deploy.sh --dry-run # 仅预检查，不部署
#   bash scripts/deploy.sh --help    # 查看帮助

PROJECT_NAME="${CF_PROJECT_NAME:-label-print-topbridge-sdk-demo}"
DIST_DIR=".vitepress/dist"
MIN_NODE_MAJOR=22

# 颜色输出
info()  { echo -e "\033[34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[32m[OK]\033[0m $*"; }
warn()  { echo -e "\033[33m[WARN]\033[0m $*"; }
error() { echo -e "\033[31m[ERROR]\033[0m $*"; exit 1; }

usage() {
  cat <<'EOF'
Cloudflare Pages 部署脚本（Direct Upload）

用法：
  bash scripts/deploy.sh
  bash scripts/deploy.sh --dry-run
  bash scripts/deploy.sh --help

选项：
  --dry-run  仅执行预检查，不构建或部署
  --help     显示帮助

环境变量：
  CF_PROJECT_NAME  Cloudflare Pages 项目名，默认 label-print-topbridge-sdk-demo
EOF
}

project_status() {
  local target="$1"

  node -e '
const target = process.argv[1];
let input = "";

process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  input += chunk;
});
process.stdin.on("end", () => {
  let parsed;

  try {
    parsed = JSON.parse(input);
  } catch (error) {
    console.error(`无法解析 Cloudflare Pages 项目列表: ${error.message}`);
    process.exit(2);
  }

  const projects = Array.isArray(parsed)
    ? parsed
    : parsed.result || parsed.projects || [];
  const found = Array.isArray(projects) && projects.some((project) => (
    project.name === target || project["Project Name"] === target
  ));

  console.log(found ? "found" : "missing");
});
' "$target"
}

DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo -e "\033[31m[ERROR]\033[0m 未知参数: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# ── 预检查 ──────────────────────────────────────────────
info "开始预检查..."

# 检查 Node 版本
NODE_MAJOR=$(node -e "console.log(process.versions.node.split('.')[0])")
if [[ "$NODE_MAJOR" -lt "$MIN_NODE_MAJOR" ]]; then
  error "Node 版本需 >= $MIN_NODE_MAJOR，当前: $(node -v)"
fi
ok "Node $(node -v)"

# 检查 pnpm
if ! command -v pnpm &>/dev/null; then
  error "pnpm 未安装。运行: npm install -g pnpm"
fi
ok "pnpm $(pnpm -v)"

# 检查 wrangler
if ! pnpm exec wrangler --version &>/dev/null; then
  error "wrangler 未安装。运行: pnpm install"
fi
ok "wrangler $(pnpm exec wrangler --version 2>/dev/null | head -1)"

# 检查 wrangler 认证状态（使用退出码而非 grep 输出）
if ! pnpm exec wrangler whoami &>/dev/null; then
  error "wrangler 未认证。运行: pnpm exec wrangler login"
fi
ok "wrangler 已认证"

# 检查 Cloudflare Pages 项目是否存在，避免 wrangler deploy 进入交互式创建流程
info "检查 Cloudflare Pages 项目: ${PROJECT_NAME}"
if ! PROJECTS_JSON=$(pnpm exec wrangler pages project list --json); then
  error "无法读取 Cloudflare Pages 项目列表。请确认 wrangler 认证状态和账号权限。"
fi

if ! PROJECT_STATUS=$(printf '%s' "$PROJECTS_JSON" | project_status "$PROJECT_NAME"); then
  error "无法解析 Cloudflare Pages 项目列表。"
fi

if [[ "$PROJECT_STATUS" != "found" ]]; then
  error "Cloudflare Pages 项目不存在: ${PROJECT_NAME}。请先运行: pnpm exec wrangler pages project create ${PROJECT_NAME} --production-branch=main"
fi
ok "Cloudflare Pages 项目存在: ${PROJECT_NAME}"

# 检查当前分支
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
if [[ "$BRANCH" != "main" ]]; then
  warn "当前分支: $BRANCH（非 main），确认要继续部署？"
fi

info "预检查全部通过"

if [[ "$DRY_RUN" == true ]]; then
  info "--dry-run 模式，跳过构建和部署"
  exit 0
fi

# ── 构建 ────────────────────────────────────────────────
info "安装依赖..."
pnpm install --frozen-lockfile

info "构建 VitePress 站点..."
pnpm build

# 验证构建产物
if [[ ! -d "$DIST_DIR" ]] || [[ -z "$(ls -A "$DIST_DIR" 2>/dev/null)" ]]; then
  error "构建产物目录 $DIST_DIR 不存在或为空"
fi

FILE_COUNT=$(find "$DIST_DIR" -type f | wc -l | tr -d ' ')
ok "构建完成，输出 $FILE_COUNT 个文件到 $DIST_DIR"

# ── 部署 ────────────────────────────────────────────────
info "部署到 Cloudflare Pages (项目: ${PROJECT_NAME})..."
pnpm exec wrangler pages deploy "$DIST_DIR" --project-name "$PROJECT_NAME"

ok "部署完成！"
