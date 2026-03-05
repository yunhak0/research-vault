#!/bin/bash
# ==============================================================================
# daily_update.sh — 기존 daily note에 누락된 내용 추가
#
# 사용법:
#   daily-update              # 어제 날짜 기준 추가 업데이트
#   daily-update 2025-02-09   # 특정 날짜 추가 업데이트
#   daily-update --help       # 도움말
#
# 설치: setup_daily.sh 실행 또는 수동으로:
#   chmod +x .vault/scripts/daily_update.sh
#   alias daily-update='<vault_path>/.vault/scripts/daily_update.sh'
# ==============================================================================

set -euo pipefail

# ─── 경로 자동 감지 ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ─── 설정 ────────────────────────────────────────────────────────────────────
DAILY_DATA_DIR="$VAULT_ROOT/.vault/daily_data"
CLAUDE_SESSION_DIR="$VAULT_ROOT/ZZ_Temp/Claude"
DAILY_NOTE_DIR="$VAULT_ROOT/01_Global/daily"
DAILY_CONF="$VAULT_ROOT/.vault/daily.conf"

# Git repos: daily.conf에서 읽기
GIT_REPOS=()
if [[ -f "$DAILY_CONF" ]]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="$(echo "$line" | xargs)"
        [[ -z "$line" ]] && continue
        eval line="$line"
        GIT_REPOS+=("$line")
    done < "$DAILY_CONF"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_section() { echo -e "\n${BLUE}━━━ $1 ━━━${NC}"; }

# ─── 메인 ──────────────────────────────────────────────────────────────────────
main() {
    local target_date=""
    
    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                echo "사용법: daily-update [날짜] [옵션]"
                echo ""
                echo "인자:"
                echo "  날짜         대상 날짜 (YYYY-MM-DD, 기본: 어제)"
                echo "  --help       도움말"
                echo ""
                echo "Vault: $VAULT_ROOT"
                echo "Config: $DAILY_CONF"
                echo "Git repos: ${#GIT_REPOS[@]}개"
                echo ""
                echo "동작:"
                echo "  1. 해당 날짜의 Claude 세션 파일 재수집"
                echo "  2. 해당 날짜의 Git 커밋 재수집"
                echo "  3. update data 파일 생성 → Claude에게 병합 요청"
                exit 0
                ;;
            *)
                target_date="$arg"
                ;;
        esac
    done
    
    if [[ -z "$target_date" ]]; then
        target_date=$(date -v-1d "+%Y-%m-%d" 2>/dev/null || date -d "yesterday" "+%Y-%m-%d")
    fi
    
    local raw_file="$DAILY_DATA_DIR/${target_date}_raw.md"
    local daily_note="$DAILY_NOTE_DIR/DAILY-${target_date}.md"
    local update_file="$DAILY_DATA_DIR/${target_date}_update.md"
    
    log_section "Daily Update: $target_date"
    log_info "Vault: $VAULT_ROOT"
    
    # 상태 확인
    if [[ -f "$raw_file" ]]; then
        log_info "기존 raw data 발견: $raw_file"
    else
        log_warn "기존 raw data 없음"
    fi
    
    if [[ -f "$daily_note" ]]; then
        log_info "기존 daily note 발견: $daily_note"
    else
        log_warn "기존 daily note 없음"
    fi
    
    # Claude 세션 파일 확인
    log_section "Claude 세션 수집"
    local claude_count=0
    for file in "$CLAUDE_SESSION_DIR"/CLAUDE-${target_date}-*.md; do
        [[ -f "$file" ]] || continue
        claude_count=$((claude_count + 1))
        log_info "  발견: $(basename "$file")"
    done
    
    if [[ $claude_count -eq 0 ]]; then
        log_warn "해당 날짜의 Claude 세션 파일 없음"
    else
        log_info "총 ${claude_count}개 세션 파일"
    fi
    
    # Git 미커밋 확인
    log_section "Git 상태 확인"
    if [[ ${#GIT_REPOS[@]} -eq 0 ]]; then
        log_warn "추적 대상 Git 저장소 없음 (.vault/daily.conf 확인)"
    else
        for repo_path in "${GIT_REPOS[@]}"; do
            [[ -d "$repo_path/.git" ]] || continue
            local repo_name
            repo_name=$(basename "$repo_path")
            local uncommitted
            uncommitted=$(cd "$repo_path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$uncommitted" -gt 0 ]]; then
                log_warn "$repo_name: ${uncommitted}개 미커밋 파일"
            else
                log_info "$repo_name: clean"
            fi
        done
    fi
    
    # Update data 생성
    log_section "Update data 생성"
    {
        echo "---"
        echo "type: daily-update-data"
        echo "date: $target_date"
        echo "generated: $(date '+%Y-%m-%dT%H:%M:%S')"
        echo "is_update: true"
        echo "---"
        echo ""
        echo "# Update Data: $target_date"
        echo ""
        echo "> 기존 daily note에 누락된 내용을 추가하기 위한 데이터"
        echo ""
        
        # Claude 세션
        echo "## Claude 대화 내역"
        echo ""
        local found=0
        for file in "$CLAUDE_SESSION_DIR"/CLAUDE-${target_date}-*.md; do
            [[ -f "$file" ]] || continue
            found=1
            echo "### $(basename "$file")"
            echo ""
            cat "$file"
            echo ""
            echo "---"
            echo ""
        done
        if [[ $found -eq 0 ]]; then
            echo "해당 날짜의 Claude 세션 기록 없음"
            echo ""
        fi
        
        # 기존 daily note
        if [[ -f "$daily_note" ]]; then
            echo "## 기존 Daily Note 내용"
            echo ""
            echo '```markdown'
            cat "$daily_note"
            echo '```'
            echo ""
        fi
        
        # 기존 raw data
        if [[ -f "$raw_file" ]]; then
            echo "## 기존 Raw Data 참조"
            echo ""
            echo "파일: \`$raw_file\`"
            echo ""
        fi
        
    } > "$update_file"
    
    log_info "Update data 저장: $update_file"
    
    log_section "완료"
    echo ""
    echo -e "  ${CYAN}📁 Update data${NC}: $update_file"
    [[ -f "$raw_file" ]] && echo -e "  ${CYAN}📁 Raw data${NC}: $raw_file"
    [[ -f "$daily_note" ]] && echo -e "  ${CYAN}📄 Daily note${NC}: $daily_note"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  다음 단계: Claude에서 ${GREEN}\"${target_date} daily note 업데이트해줘\"${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"
