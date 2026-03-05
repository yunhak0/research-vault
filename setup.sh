#!/bin/bash
# ==============================================================================
# setup.sh — Research Vault 설치 및 관리
#
# 사용법:
#   bash setup.sh install [경로]       # 새 vault 초기 구성
#   bash setup.sh project              # 프로젝트 추가
#   bash setup.sh daily                # daily 자동화 설치
#   bash setup.sh wandb                # W&B MCP 서버 설정
#   bash setup.sh obsidian             # Obsidian MCP 서버 설정
#   bash setup.sh context7             # Context7 MCP 서버 설정 (라이브러리 문서 조회)
#   bash setup.sh --help               # 도움말
#
# 테스트:
#   source setup.sh 로 함수만 로드 가능 (source guard 적용)
#   테스트 가능한 core 함수: _install_vault, _ensure_repo, _setup_project
#
# 저장소: github.com/yunhak0/research-vault
# ==============================================================================

set -euo pipefail

# ─── 경로 ─────────────────────────────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_CORE="$REPO_DIR/vault_core"
PROJECT_TEMPLATE="$REPO_DIR/project_template"
VAULT_PATH_CACHE="$HOME/.research-vault-path"

# ─── 색상 ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ─── 유틸리티 ─────────────────────────────────────────────────────────────────

# 사용자 입력 (프롬프트, 기본값)
ask() {
    local prompt="$1"
    local default="${2:-}"
    local result

    if [[ -n "$default" ]]; then
        read -rp "  $prompt [$default]: " result
        echo "${result:-$default}"
    else
        read -rp "  $prompt: " result
        echo "$result"
    fi
}

# Y/N 확인
confirm() {
    local prompt="$1"
    local answer
    read -rp "  $prompt (y/n): " answer
    [[ "$answer" =~ ^[Yy] ]]
}

# 파일 내 플레이스홀더 치환
replace_placeholder() {
    local file="$1"
    local placeholder="$2"
    local value="$3"

    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|{{${placeholder}}}|${value}|g" "$file"
    else
        sed -i "s|{{${placeholder}}}|${value}|g" "$file"
    fi
}

# ==============================================================================
# CORE 함수 (testable — interactive 입력 없음)
# ==============================================================================

# ─── _install_vault: vault 디렉토리 구조 + 파일 생성 ─────────────────────────
# 인자: vault_path, owner
# 반환: 0=성공
_install_vault() {
    local vault_path="$1"
    local owner="$2"

    # 1. 디렉토리 생성
    log_section "디렉토리 생성"

    local dirs=(
        ".vault/templates"
        ".vault/guides"
        ".vault/scripts"
        ".vault/daily_data"
        ".vault/skills"
        "01_Global/daily"
        "01_Global/literature"
        "ZZ_Temp/Claude"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$vault_path/$dir"
        echo "  ✅ $dir/"
    done

    # 2. 핵심 파일 복사
    log_section "핵심 파일 복사"

    cp "$VAULT_CORE/CLAUDE.md" "$vault_path/CLAUDE.md"
    echo "  ✅ CLAUDE.md"

    if [[ -f "$vault_path/.vault/config.yaml" ]]; then
        log_warn "config.yaml 이미 존재 — 건너뜀 (기존 설정 보존)"
    else
        cp "$VAULT_CORE/config.yaml" "$vault_path/.vault/config.yaml"
        echo "  ✅ .vault/config.yaml"
    fi

    if [[ -f "$vault_path/.vault/daily.conf" ]]; then
        log_warn "daily.conf 이미 존재 — 건너뜀"
    else
        cp "$VAULT_CORE/daily.conf" "$vault_path/.vault/daily.conf"
        echo "  ✅ .vault/daily.conf"
    fi

    # templates
    for file in "$VAULT_CORE/templates/"*.md; do
        [[ -f "$file" ]] || continue
        cp "$file" "$vault_path/.vault/templates/"
    done
    local t_count
    t_count=$(ls -1 "$VAULT_CORE/templates/"*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ .vault/templates/ (${t_count}개)"

    # guides
    for file in "$VAULT_CORE/guides/"*.md; do
        [[ -f "$file" ]] || continue
        cp "$file" "$vault_path/.vault/guides/"
    done
    local g_count
    g_count=$(ls -1 "$VAULT_CORE/guides/"*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ .vault/guides/ (${g_count}개)"

    # scripts
    for file in "$VAULT_CORE/scripts/"*; do
        [[ -f "$file" ]] || continue
        cp "$file" "$vault_path/.vault/scripts/"
    done
    local s_count
    s_count=$(ls -1 "$VAULT_CORE/scripts/"* 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✅ .vault/scripts/ (${s_count}개)"

    # .claude/
    mkdir -p "$vault_path/.claude/hooks"
    if [[ -f "$VAULT_CORE/.claude/settings.local.json" ]]; then
        cp "$VAULT_CORE/.claude/settings.local.json" "$vault_path/.claude/settings.local.json"
    fi
    for file in "$VAULT_CORE/.claude/hooks/"*; do
        [[ -f "$file" ]] || continue
        cp "$file" "$vault_path/.claude/hooks/"
        chmod +x "$vault_path/.claude/hooks/$(basename "$file")"
    done
    echo "  ✅ .claude/ (settings + hooks)"

    # 3. config.yaml 설정
    log_section "기본 설정"

    local config_file="$vault_path/.vault/config.yaml"

    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|^  path: \"\"$|  path: \"$vault_path\"|" "$config_file"
    else
        sed -i "s|^  path: \"\"$|  path: \"$vault_path\"|" "$config_file"
    fi
    echo "  ✅ vault.path = $vault_path"

    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|^  owner: \"\"$|  owner: \"$owner\"|" "$config_file"
    else
        sed -i "s|^  owner: \"\"$|  owner: \"$owner\"|" "$config_file"
    fi
    echo "  ✅ vault.owner = $owner"

    # 4. 경로 캐시
    echo "$vault_path" > "$VAULT_PATH_CACHE"
}

# ─── _ensure_repo: 저장소 생성/확인 ──────────────────────────────────────────
# 인자: code_repo, method ("uv" | "git" | "existing")
# 반환: 0=성공, 1=실패
_ensure_repo() {
    local code_repo="$1"
    local method="$2"

    case "$method" in
        uv)
            if ! command -v uv &>/dev/null; then
                log_info "uv가 설치되어 있지 않습니다. 설치를 시도합니다..."
                if curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null; then
                    export PATH="$HOME/.local/bin:$PATH"
                    if ! command -v uv &>/dev/null; then
                        log_error "uv 설치 후 PATH에서 찾을 수 없습니다."
                        return 1
                    fi
                    log_info "uv 설치 완료: $(uv --version)"
                else
                    log_error "uv 설치 실패. https://docs.astral.sh/uv/ 에서 수동 설치하세요."
                    return 1
                fi
            fi
            log_info "uv init: $code_repo"
            mkdir -p "$(dirname "$code_repo")"
            uv init --python 3.11 "$code_repo"
            (cd "$code_repo" && git init && git add -A && git commit -m "chore: initial project scaffold (uv init)")
            log_info "Python 프로젝트 생성 완료 (uv + git)"
            ;;
        git)
            mkdir -p "$code_repo"
            (cd "$code_repo" && git init)
            log_info "빈 Git 저장소 생성 완료"
            ;;
        existing)
            # 이미 존재 — 아무것도 안 함
            ;;
        *)
            log_error "알 수 없는 method: $method"
            return 1
            ;;
    esac
    return 0
}

# ─── _setup_project: 프로젝트 구조 생성 + vault 연결 ─────────────────────────
# 인자: vault_path, project_id, project_name, project_desc, code_repo
# 전제: code_repo가 이미 존재해야 함
# 반환: 0=성공, 1=실패
_setup_project() {
    local vault_path="$1"
    local project_id="$2"
    local project_name="$3"
    local project_desc="$4"
    local code_repo="${5:-}"  # 빈 문자열이면 vault에 직접 생성

    local project_dir="${project_id}_${project_name}"
    local vault_project="$vault_path/$project_dir"

    # vault 충돌 확인
    if [[ -e "$vault_project" ]]; then
        log_error "Vault에 이미 존재합니다: $vault_project"
        return 1
    fi

    log_section "프로젝트 생성: $project_dir"

    # ── mode 결정: repo 연결 vs vault 직접 생성 ──
    local mode="repo"
    if [[ -z "$code_repo" ]] || [[ ! -d "$code_repo" ]]; then
        mode="vault_only"
    fi

    local obsidian_dir
    local today
    today=$(date "+%Y-%m-%d")

    if [[ "$mode" == "repo" ]]; then
        # ── repo 모드: agent-docs를 repo에 생성, vault에 symlink ──
        obsidian_dir="$code_repo/agent-docs/obsidian"

        # 1. agent-docs/ 구조 복사
        local template_docs="$PROJECT_TEMPLATE/agent-docs"
        if [[ -d "$template_docs" ]]; then
            mkdir -p "$code_repo/agent-docs"
            cp -rn "$template_docs/" "$code_repo/agent-docs/" 2>/dev/null || \
            cp -r "$template_docs/" "$code_repo/agent-docs/"
            find "$code_repo/agent-docs" -name ".DS_Store" -delete 2>/dev/null || true
            echo "  ✅ agent-docs/ 구조 → 프로젝트 repo (obsidian/ + tasks/ + analyze/)"
        fi

        # 2. README.md
        if [[ ! -f "$obsidian_dir/README.md" ]] && [[ -f "$PROJECT_TEMPLATE/README.md" ]]; then
            cp "$PROJECT_TEMPLATE/README.md" "$obsidian_dir/README.md"
            echo "  ✅ agent-docs/obsidian/README.md (프로젝트 문서 정의서)"
        fi

        # 2b. CLAUDE.md
        if [[ ! -f "$code_repo/CLAUDE.md" ]] && [[ -f "$PROJECT_TEMPLATE/CLAUDE.md" ]]; then
            cp "$PROJECT_TEMPLATE/CLAUDE.md" "$code_repo/CLAUDE.md"
            echo "  ✅ CLAUDE.md (코딩 에이전트 설정)"
        elif [[ -f "$code_repo/CLAUDE.md" ]]; then
            log_warn "CLAUDE.md 이미 존재 — 건너뜀"
        fi

        # 2c. .claude/
        if [[ ! -d "$code_repo/.claude" ]] && [[ -d "$PROJECT_TEMPLATE/.claude" ]]; then
            cp -r "$PROJECT_TEMPLATE/.claude" "$code_repo/.claude"
            echo "  ✅ .claude/ (Claude Code hooks + settings)"
        elif [[ -d "$code_repo/.claude" ]]; then
            log_warn ".claude/ 이미 존재 — 건너뜀"
        fi

        # 3. 플레이스홀더 치환
        for file in "$obsidian_dir/README.md" "$obsidian_dir/00_project_index.md" "$code_repo/CLAUDE.md"; do
            if [[ -f "$file" ]]; then
                replace_placeholder "$file" "PROJECT_ID" "$project_id"
                replace_placeholder "$file" "PROJECT_NAME" "$project_name"
                replace_placeholder "$file" "PROJECT_DESCRIPTION" "$project_desc"
                replace_placeholder "$file" "CREATED_DATE" "$today"
                replace_placeholder "$file" "ARCHITECTURE_SUMMARY" "(미정)"
                replace_placeholder "$file" "WANDB_PROJECT" "(미정)"
            fi
        done
        echo "  ✅ 플레이스홀더 치환"

        # 4. Vault symlink
        ln -s "$obsidian_dir" "$vault_project"
        echo "  ✅ Vault symlink: $project_dir → $code_repo/agent-docs/obsidian"

        # 5. daily.conf
        local conf_file="$vault_path/.vault/daily.conf"
        if ! grep -q "$code_repo" "$conf_file" 2>/dev/null; then
            echo "$code_repo" >> "$conf_file"
            echo "  ✅ daily.conf에 추가"
        fi
    else
        # ── vault_only 모드: vault에 직접 obsidian 구조 생성 ──
        obsidian_dir="$vault_project"

        # 1. obsidian 구조만 복사 (agent-docs/obsidian 내용을 vault에 직접)
        local template_obsidian="$PROJECT_TEMPLATE/agent-docs/obsidian"
        if [[ -d "$template_obsidian" ]]; then
            mkdir -p "$obsidian_dir"
            cp -rn "$template_obsidian/" "$obsidian_dir/" 2>/dev/null || \
            cp -r "$template_obsidian/" "$obsidian_dir/"
            find "$obsidian_dir" -name ".DS_Store" -delete 2>/dev/null || true
            echo "  ✅ Obsidian 문서 구조 → vault 직접 생성"
        fi

        # 2. README.md
        if [[ ! -f "$obsidian_dir/README.md" ]] && [[ -f "$PROJECT_TEMPLATE/README.md" ]]; then
            cp "$PROJECT_TEMPLATE/README.md" "$obsidian_dir/README.md"
            echo "  ✅ README.md (프로젝트 문서 정의서)"
        fi

        # 3. 플레이스홀더 치환
        for file in "$obsidian_dir/README.md" "$obsidian_dir/00_project_index.md"; do
            if [[ -f "$file" ]]; then
                replace_placeholder "$file" "PROJECT_ID" "$project_id"
                replace_placeholder "$file" "PROJECT_NAME" "$project_name"
                replace_placeholder "$file" "PROJECT_DESCRIPTION" "$project_desc"
                replace_placeholder "$file" "CREATED_DATE" "$today"
                replace_placeholder "$file" "ARCHITECTURE_SUMMARY" "(미정)"
                replace_placeholder "$file" "WANDB_PROJECT" "(미정)"
            fi
        done
        echo "  ✅ 플레이스홀더 치환"

        echo "  ℹ️  Vault에 직접 생성됨 (symlink 없음)"
        echo "  ℹ️  나중에 repo 연결 시: rm -rf $vault_project && ln -s <repo>/agent-docs/obsidian $vault_project"
    fi

    # 6. config.yaml (양쪽 모드 공통)
    _add_project_to_config "$vault_path" "$project_id" "$project_name" "$code_repo"

    return 0
}

# ─── _add_project_to_config: config.yaml에 프로젝트 추가 ─────────────────────
_add_project_to_config() {
    local vault_path="$1"
    local project_id="$2"
    local project_name="$3"
    local code_repo="${4:-}"

    local config_file="$vault_path/.vault/config.yaml"

    local entry="  - {id: \"$project_id\", name: \"$project_name\""
    if [[ -n "$code_repo" ]]; then
        entry="$entry, code_repo: \"$code_repo\""
    fi
    entry="$entry}"

    if grep -q "^projects: \[\]" "$config_file"; then
        awk -v entry="$entry" '
            /^projects: \[\]/ { print "projects:"; print entry; next }
            { print }
        ' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"
    else
        echo "$entry" >> "$config_file"
    fi
    echo "  ✅ config.yaml projects[] 업데이트"
}

# ==============================================================================
# INTERACTIVE 명령 (사용자 입력 수집 → core 함수 호출)
# ==============================================================================

# ─── install ──────────────────────────────────────────────────────────────────
cmd_install() {
    local vault_path="${1:-}"

    echo -e "${BOLD}━━━ Research Vault 설치 ━━━${NC}"
    echo ""

    # Vault 경로
    if [[ -z "$vault_path" ]]; then
        vault_path=$(ask "Vault 경로" "$HOME/Documents/obsidian")
    fi
    vault_path="${vault_path/#\~/$HOME}"
    vault_path="$(cd "$(dirname "$vault_path")" 2>/dev/null && pwd)/$(basename "$vault_path")" || vault_path="$vault_path"

    if [[ -d "$vault_path/.vault" ]]; then
        log_warn "이미 .vault/가 존재합니다: $vault_path"
        if ! confirm "덮어쓸까요? (기존 config.yaml은 보존됩니다)"; then
            echo "취소되었습니다."
            exit 0
        fi
    fi

    echo ""
    log_info "Vault 경로: $vault_path"

    # Owner
    local owner
    owner=$(ask "Vault 소유자 이름" "$(whoami)")

    # ── Core 호출 ──
    _install_vault "$vault_path" "$owner"

    # Daily 자동화 (interactive)
    echo ""
    if confirm "Daily 자동화도 설치할까요? (alias 등록)"; then
        _setup_daily "$vault_path"
    else
        log_info "나중에 'bash setup.sh daily'로 설치할 수 있습니다."
    fi

    # 완료
    log_section "설치 완료"
    echo ""
    echo -e "  ${CYAN}📁 Vault${NC}: $vault_path"
    echo -e "  ${CYAN}📄 Config${NC}: $vault_path/.vault/config.yaml"
    echo -e "  ${CYAN}📄 CLAUDE.md${NC}: $vault_path/CLAUDE.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  다음 단계:"
    echo -e "    1. ${GREEN}bash setup.sh project${NC}  → 첫 프로젝트 생성"
    echo -e "    2. Claude에서 대화 시작 → config.yaml 빈 값 자동 질문"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ─── project ──────────────────────────────────────────────────────────────────
#
# 구조: 프로젝트 repo가 docs + code를 모두 소유하고,
#       vault에서는 symlink으로 agent-docs/obsidian/ 만 참조한다.
#
#   ~/github/P001_scDiffuser/     ← 프로젝트 repo
#   │ ├── agent-docs/
#   │ │   ├── obsidian/            ← 연구 문서 (이 스크립트가 생성)
#   │ │   ├── tasks/               ← 코딩 에이전트 작업 추적
#   │ │   └── analyze/             ← 분석 스크립트·결과
#   │ ├── src/                     ← 코드 (기존)
#   │ └── CLAUDE.md                ← 코딩 에이전트 설정
#
#   ~/Documents/obsidian/          ← vault
#   └── P001_scDiffuser/           ← symlink → ~/github/.../agent-docs/obsidian
#
cmd_project() {
    echo -e "${BOLD}━━━ 프로젝트 추가 ━━━${NC}"
    echo ""

    # Vault 경로
    local vault_path=""
    vault_path=$(_find_vault)
    if [[ -z "$vault_path" ]]; then
        log_error "Vault를 찾을 수 없습니다. 먼저 'bash setup.sh install'을 실행하세요."
        exit 1
    fi
    log_info "Vault: $vault_path"

    # 프로젝트 정보
    echo ""
    local project_id
    project_id=$(ask "프로젝트 ID" "P001")
    project_id=$(echo "$project_id" | tr '[:lower:]' '[:upper:]')

    local project_name
    project_name=$(ask "프로젝트 이름" "scDiffuser")

    local project_desc
    project_desc=$(ask "프로젝트 한줄 설명")

    # 저장소 경로
    echo ""
    log_info "프로젝트 repo가 docs와 code를 모두 소유합니다."
    log_info "vault에는 symlink만 생성됩니다."
    echo ""
    local code_repo
    local repo_hint=""
    local conf_file="$vault_path/.vault/daily.conf"
    if [[ -f "$conf_file" ]]; then
        local repo_count
        repo_count=$(grep -cv '^#\|^$' "$conf_file" 2>/dev/null || echo 0)
        local last_repo
        last_repo=$(grep -v '^#\|^$' "$conf_file" | tail -1 | xargs)
        if [[ -n "$last_repo" ]]; then
            if [[ "$repo_count" -le 1 ]]; then
                repo_hint="$last_repo"
            else
                repo_hint="$(dirname "$last_repo")/"
            fi
        fi
    fi
    code_repo=$(ask "Git 로컬 저장소 경로" "$repo_hint")
    code_repo="${code_repo/#\~/$HOME}"
    # ── 저장소 상태에 따른 분기 (interactive) ──
    local repo_method="existing"
    if [[ ! -d "$code_repo" ]]; then
        echo ""
        log_warn "경로가 존재하지 않습니다: $code_repo"
        echo ""
        echo "  어떻게 할까요?"
        echo ""
        echo -e "    ${CYAN}1${NC}) uv init — Python 프로젝트 생성 (pyproject.toml, .venv, src/) ${GREEN}[권장]${NC}"
        echo -e "    ${CYAN}2${NC}) git init — 빈 Git 저장소만 생성"
        echo -e "    ${CYAN}3${NC}) Vault에 직접 생성 — repo 없이 문서 구조만 먼저 (나중에 repo 연결)"
        echo -e "    ${CYAN}4${NC}) 취소"
        echo ""
        local init_choice
        init_choice=$(ask "선택 (1/2/3/4)" "1")

        case "$init_choice" in
            1) repo_method="uv" ;;
            2) repo_method="git" ;;
            3) repo_method="vault_only" ;;
            *)
                echo "취소되었습니다."
                exit 0
                ;;
        esac
    elif [[ ! -d "$code_repo/.git" ]]; then
        log_warn "Git 저장소가 아닙니다: $code_repo"
        if ! confirm "그래도 계속할까요?"; then
            echo "취소되었습니다."
            exit 0
        fi
    fi

    # agent-docs 존재 확인 (interactive, repo 모드에서만)
    if [[ "$repo_method" != "vault_only" ]] && [[ -d "$code_repo/agent-docs/obsidian" ]]; then
        log_warn "프로젝트 repo에 이미 agent-docs/obsidian/ 폴더가 존재합니다."
        if ! confirm "기존 agent-docs/obsidian/ 안에 연구 문서 구조를 추가할까요? (기존 파일은 유지)"; then
            echo "취소되었습니다."
            exit 0
        fi
    fi

    # ── Core 호출 ──
    if [[ "$repo_method" == "vault_only" ]]; then
        _setup_project "$vault_path" "$project_id" "$project_name" "$project_desc" "" || exit 1
    else
        if [[ "$repo_method" != "existing" ]]; then
            _ensure_repo "$code_repo" "$repo_method" || exit 1
        fi
        _setup_project "$vault_path" "$project_id" "$project_name" "$project_desc" "$code_repo" || exit 1
    fi

    # 플러그인 (optional, repo 모드에서만)
    if [[ "$repo_method" != "vault_only" ]]; then
        if command -v claude &>/dev/null; then
            log_section "Claude Code 플러그인"
            if (cd "$code_repo" && claude plugin install ralph-loop@claude-plugins-official --scope project 2>/dev/null); then
                echo "  ✅ ralph-loop 플러그인 설치 (자율 반복 루프)"
            else
                log_warn "ralph-loop 설치 실패 — Claude Code에서 직접 설치하세요:"
                echo "    /plugin install ralph-loop@claude-plugins-official"
            fi
            if (cd "$code_repo" && claude plugin install claude-hud@claude-hud --scope user 2>/dev/null); then
                echo "  ✅ claude-hud 플러그인 설치 (상태 표시줄)"
            else
                log_warn "claude-hud 설치 실패 — Claude Code에서 직접 설치하세요:"
                echo "    /plugin install claude-hud@claude-hud"
            fi
        else
            log_info "Claude Code CLI 미감지 — 플러그인은 첫 세션에서 설치하세요:"
            echo "    /plugin install ralph-loop@claude-plugins-official"
            echo "    /plugin install claude-hud@claude-hud"
        fi
    fi

    # 완료
    local project_dir="${project_id}_${project_name}"
    log_section "프로젝트 생성 완료"
    echo ""
    if [[ "$repo_method" == "vault_only" ]]; then
        echo -e "  ${CYAN}📁 Vault 프로젝트${NC}: $vault_path/$project_dir"
        echo -e "  ${CYAN}📄 문서 정의서${NC}: $vault_path/$project_dir/README.md"
        echo -e "  ${CYAN}📄 프로젝트 인덱스${NC}: $vault_path/$project_dir/00_project_index.md"
        echo -e "  ${YELLOW}⚠ Repo 미연결${NC}: 나중에 repo 생성 후 symlink으로 전환 가능"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "  다음 단계:"
        echo -e "    1. Obsidian에서 ${GREEN}$project_dir${NC} 폴더 확인"
        echo -e "    2. README.md에서 미정 항목 채우기"
        echo -e "    3. Repo 생성 후 연결:"
        echo -e "       ${CYAN}rm -rf $vault_path/$project_dir${NC}"
        echo -e "       ${CYAN}ln -s <repo>/agent-docs/obsidian $vault_path/$project_dir${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo -e "  ${CYAN}📁 프로젝트 repo${NC}: $code_repo"
        echo -e "  ${CYAN}🤖 CLAUDE.md${NC}: $code_repo/CLAUDE.md ([TODO] → 첫 세션에서 자동 채움)"
        echo -e "  ${CYAN}📄 문서 정의서${NC}: $code_repo/agent-docs/obsidian/README.md"
        echo -e "  ${CYAN}📄 프로젝트 인덱스${NC}: $code_repo/agent-docs/obsidian/00_project_index.md"
        echo -e "  ${CYAN}🔗 Vault symlink${NC}: $vault_path/$project_dir → $code_repo/agent-docs/obsidian"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "  다음 단계:"
        echo -e "    1. ${GREEN}Claude Code 첫 세션${NC} → CLAUDE.md의 [TODO] 마커가 자동으로 채워짐"
        echo -e "    2. agent-docs/obsidian/README.md에서 ${GREEN}ARCHITECTURE_SUMMARY${NC}, ${GREEN}WANDB_PROJECT${NC} 등 미정 항목 채우기"
        echo -e "    3. Obsidian에서 $project_dir 폴더가 정상 표시되는지 확인"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
}

# ─── daily ────────────────────────────────────────────────────────────────────
cmd_daily() {
    echo -e "${BOLD}━━━ Daily 자동화 설치 ━━━${NC}"
    echo ""

    local vault_path=""
    vault_path=$(_find_vault)
    if [[ -z "$vault_path" ]]; then
        log_error "Vault를 찾을 수 없습니다. 먼저 'bash setup.sh install'을 실행하세요."
        exit 1
    fi

    _setup_daily "$vault_path"
}

# ─── wandb ─────────────────────────────────────────────────────────────────
cmd_wandb() {
    echo -e "${BOLD}━━━ W&B MCP 서버 설정 ━━━${NC}"
    echo ""

    # 1. claude CLI 확인
    if ! command -v claude &>/dev/null; then
        log_error "Claude Code CLI가 설치되어 있지 않습니다."
        echo "  https://docs.anthropic.com/en/docs/claude-code 에서 설치하세요."
        exit 1
    fi

    # 2. API 키: 환경변수 우선, 없으면 수동 입력
    local api_key="${WANDB_API_KEY:-}"
    if [[ -n "$api_key" ]]; then
        log_info "WANDB_API_KEY 환경변수 감지 — 기존 키 사용"
    else
        api_key=$(ask "WANDB_API_KEY (https://wandb.ai/authorize)")
        if [[ -z "$api_key" ]]; then
            log_error "API 키가 비어 있습니다."
            exit 1
        fi
    fi

    # 3. shell rc에 export 추가
    local shell_rc="$HOME/.zshrc"
    if [[ ! -f "$shell_rc" ]]; then
        shell_rc="$HOME/.bashrc"
    fi

    if grep -q "WANDB_API_KEY" "$shell_rc" 2>/dev/null; then
        log_warn "WANDB_API_KEY가 이미 ${shell_rc}에 존재합니다 — 건너뜀"
    else
        {
            echo ""
            echo "# === W&B API Key ==="
            echo "export WANDB_API_KEY=\"$api_key\""
        } >> "$shell_rc"
        echo "  ✅ export WANDB_API_KEY 추가 (${shell_rc})"
    fi

    # 4. MCP 등록 (글로벌)
    log_section "Claude Code MCP 등록"
    local mcp_output
    if mcp_output=$(claude mcp add wandb \
        --scope user \
        -e "WANDB_API_KEY=$api_key" \
        -- uvx --from "git+https://github.com/wandb/wandb-mcp-server" wandb_mcp_server 2>&1); then
        echo "  ✅ wandb MCP 서버 등록 완료 (scope: user)"
    elif echo "$mcp_output" | grep -qi "already exists"; then
        log_warn "wandb MCP 서버가 이미 등록되어 있습니다 — 건너뛰"
    else
        log_error "MCP 등록 실패: $mcp_output"
        exit 1
    fi

    # 5. 완료 안내
    log_section "설정 완료"
    echo ""
    echo -e "  ${CYAN}🔑 API Key${NC}: ${shell_rc}에 저장됨"
    echo -e "  ${CYAN}🔌 MCP${NC}: wandb (scope: user — 모든 프로젝트에서 사용 가능)"
    echo ""
    echo -e "  ${YELLOW}⚠ Claude Code를 재시작하세요${NC} (이미 실행 중이라면)"
    echo ""
}

# ─── obsidian ─────────────────────────────────────────────────────────────────
cmd_obsidian() {
    echo -e "${BOLD}━━━ Obsidian MCP 서버 설정 ━━━${NC}"
    echo ""

    # 1. claude CLI 확인
    if ! command -v claude &>/dev/null; then
        log_error "Claude Code CLI가 설치되어 있지 않습니다."
        echo "  https://docs.anthropic.com/en/docs/claude-code 에서 설치하세요."
        exit 1
    fi

    # 2. Vault 경로 입력
    local vault_path=""
    vault_path=$(_find_vault)
    if [[ -z "$vault_path" ]]; then
        log_error "Vault를 찾을 수 없습니다. 먼저 'bash setup.sh install'을 실행하세요."
        exit 1
    fi
    log_info "Vault: $vault_path"

    # 3. MCP 등록 (글로벌)
    log_section "Claude Code MCP 등록"
    local mcp_output
    if mcp_output=$(claude mcp add mcp-obsidian \
        --scope user \
        -- npx -y mcp-obsidian "$vault_path" 2>&1); then
        echo "  ✅ mcp-obsidian 서버 등록 완료 (scope: user)"
    elif echo "$mcp_output" | grep -qi "already exists"; then
        log_warn "mcp-obsidian 서버가 이미 등록되어 있습니다 — 건너뛰"
    else
        log_error "MCP 등록 실패: $mcp_output"
        exit 1
    fi

    # 4. 완료 안내
    log_section "설정 완료"
    echo ""
    echo -e "  ${CYAN}📁 Vault${NC}: $vault_path"
    echo -e "  ${CYAN}🔌 MCP${NC}: mcp-obsidian (scope: user — 모든 프로젝트에서 사용 가능)"
    echo ""
    echo -e "  ${YELLOW}⚠ Claude Code를 재시작하세요${NC} (이미 실행 중이라면)"
    echo ""
}

# ─── context7 ─────────────────────────────────────────────────────────────────
cmd_context7() {
    echo -e "${BOLD}━━━ Context7 MCP 서버 설정 ━━━${NC}"
    echo ""

    # 1. claude CLI 확인
    if ! command -v claude &>/dev/null; then
        log_error "Claude Code CLI가 설치되어 있지 않습니다."
        echo "  https://docs.anthropic.com/en/docs/claude-code 에서 설치하세요."
        exit 1
    fi

    # 2. npx 확인
    if ! command -v npx &>/dev/null; then
        log_error "npx가 설치되어 있지 않습니다. Node.js를 설치하세요."
        exit 1
    fi

    # 3. MCP 등록 (글로벌)
    log_section "Claude Code MCP 등록"
    local mcp_output
    if mcp_output=$(claude mcp add context7 \
        --scope user \
        -- npx -y @upstash/context7-mcp 2>&1); then
        echo "  ✅ context7 MCP 서버 등록 완료 (scope: user)"
    elif echo "$mcp_output" | grep -qi "already exists"; then
        log_warn "context7 서버가 이미 등록되어 있습니다 — 건너뛰"
    else
        log_error "MCP 등록 실패: $mcp_output"
        exit 1
    fi

    # 4. 완료 안내
    log_section "설정 완료"
    echo ""
    echo -e "  ${CYAN}📚 Context7${NC}: 라이브러리 문서 조회 (PyTorch, HuggingFace, diffusers 등)"
    echo -e "  ${CYAN}🔌 MCP${NC}: context7 (scope: user — 모든 프로젝트에서 사용 가능)"
    echo ""
    echo -e "  ${YELLOW}⚠ Claude Code를 재시작하세요${NC} (이미 실행 중이라면)"
    echo ""
}

# ==============================================================================
# 내부 함수
# ==============================================================================

# Vault 경로 찾기
_find_vault() {
    if [[ -f ".vault/config.yaml" ]]; then
        pwd
        return
    fi

    local saved_path=""
    if [[ -f "$VAULT_PATH_CACHE" ]]; then
        saved_path=$(cat "$VAULT_PATH_CACHE" 2>/dev/null | xargs)
    fi

    local vault_path
    vault_path=$(ask "Vault 경로" "${saved_path:-$HOME/Documents/obsidian}")
    vault_path="${vault_path/#\~/$HOME}"

    if [[ ! -d "$vault_path/.vault" ]]; then
        echo ""
        return
    fi

    echo "$vault_path"
}

# Daily 자동화 설치
_setup_daily() {
    local vault_path="$1"
    local scripts_dir="$vault_path/.vault/scripts"

    log_section "Daily 자동화 설치"

    mkdir -p "$vault_path/.vault/daily_data"
    mkdir -p "$vault_path/ZZ_Temp/Claude"

    chmod +x "$scripts_dir/daily_start.sh" 2>/dev/null || true
    chmod +x "$scripts_dir/daily_update.sh" 2>/dev/null || true
    echo "  ✅ 스크립트 실행 권한 설정"

    local shell_rc="$HOME/.zshrc"
    if [[ ! -f "$shell_rc" ]]; then
        shell_rc="$HOME/.bashrc"
    fi

    if grep -q "daily-start" "$shell_rc" 2>/dev/null; then
        log_warn "alias가 이미 등록되어 있습니다."
        echo "  경로가 변경되었다면 수동 업데이트:"
        echo "    alias daily-start='$scripts_dir/daily_start.sh'"
        echo "    alias daily-update='$scripts_dir/daily_update.sh'"
    else
        {
            echo ""
            echo "# === Research Vault Daily 자동화 ==="
            echo "alias daily-start='$scripts_dir/daily_start.sh'"
            echo "alias daily-update='$scripts_dir/daily_update.sh'"
        } >> "$shell_rc"
        echo "  ✅ alias 등록 (${shell_rc})"
    fi

    local conf_file="$vault_path/.vault/daily.conf"
    echo ""
    if confirm "추적할 Git 저장소를 추가할까요?"; then
        echo "  (여러 저장소를 연속 추가할 수 있습니다. 없거나 완료했으면 Enter)"
        while true; do
            local repo
            repo=$(ask "Git 저장소 로컬 경로")
            [[ -z "$repo" ]] && break
            repo="${repo/#\~/$HOME}"
            if [[ -d "$repo/.git" ]]; then
                if ! grep -q "$repo" "$conf_file" 2>/dev/null; then
                    echo "$repo" >> "$conf_file"
                    echo "  ✅ 추가: $repo"
                else
                    log_warn "이미 등록됨: $repo"
                fi
            else
                log_warn "Git 저장소가 아닙니다: $repo"
            fi
        done
    fi

    echo ""
    log_info "완료. 터미널에서 'source $shell_rc' 실행 후 사용하세요."
    echo ""
    echo "  사용법:"
    echo "    daily-start          → 어제 데이터 수집 + 오늘 빈 템플릿"
    echo "    daily-update         → 어제 daily note 추가 업데이트"
    echo "    daily-update 날짜   → 특정 날짜 업데이트"
}

# ─── 도움말 ───────────────────────────────────────────────────────────────────
cmd_help() {
    echo -e "${BOLD}Research Vault Setup${NC}"
    echo ""
    echo "사용법: bash setup.sh <명령> [옵션]"
    echo ""
    echo "명령:"
    echo "  install [경로]   새 vault 초기 구성"
    echo "  project          프로젝트 추가"
    echo "  daily            daily 자동화 설치"
    echo "  wandb            W&B MCP 서버 설정 (API key + Claude Code 연결)"
    echo "  obsidian         Obsidian MCP 서버 설정 (vault 연결)"
    echo "  context7         Context7 MCP 서버 설정 (라이브러리 문서 조회)"
    echo "  --help           이 도움말"
    echo ""
    echo "일반적인 흐름:"
    echo "  1. bash setup.sh install        → vault 생성"
    echo "  2. bash setup.sh project        → 첫 프로젝트 추가"
    echo "  3. Claude에서 대화 시작          → 빈 설정값 자동 질문"
    echo ""
}

# ─── 메인 ─────────────────────────────────────────────────────────────────────
main() {
    local cmd="${1:-}"
    shift 2>/dev/null || true

    case "$cmd" in
        install)  cmd_install "$@" ;;
        project)  cmd_project "$@" ;;
        daily)    cmd_daily "$@" ;;
        wandb)    cmd_wandb "$@" ;;
        obsidian) cmd_obsidian "$@" ;;
        context7) cmd_context7 "$@" ;;
        --help|-h|help|"")  cmd_help ;;
        *)
            log_error "알 수 없는 명령: $cmd"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

# Source guard: `source setup.sh` 시 main 실행 안 함
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi