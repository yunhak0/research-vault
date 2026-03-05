#!/bin/bash
# ==============================================================================
# test_setup.sh — setup.sh 통합 테스트
#
# 사용법:
#   bash tests/test_setup.sh               # 전체 테스트
#   bash tests/test_setup.sh test_install   # 개별 테스트
#   bash tests/test_setup.sh -l             # 테스트 목록
#   bash tests/test_setup.sh -v             # verbose (임시 파일 보존)
#
# Core 함수를 직접 호출하여 테스트 — stdin 파이핑 없음
# ==============================================================================

set -uo pipefail

# ─── 설정 ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# setup.sh를 source하여 core 함수 로드 (main은 실행 안 됨 — source guard)
source "$REPO_DIR/setup.sh"
set +e  # setup.sh의 set -e 해제 — assertion 실패 시 스크립트 종료 방지

VERBOSE=false
TEST_ROOT=""
PASS=0
FAIL=0
SKIP=0

# ─── 색상 (setup.sh에서 이미 정의됨, 테스트 전용 추가) ───────────────────────
T_BLUE='\033[0;34m'

# ─── Assertion 함수 ──────────────────────────────────────────────────────────
_pass()  { echo -e "  ${GREEN}✅ PASS${NC}: $1"; ((PASS++)) || true; }
_fail()  { echo -e "  ${RED}❌ FAIL${NC}: $1"; ((FAIL++)) || true; }
_skip()  { echo -e "  ${YELLOW}⏭  SKIP${NC}: $1"; ((SKIP++)) || true; }

assert_dir()      { [[ -d "$1" ]] && _pass "$2" || _fail "$2 — 디렉토리 없음: $1"; }
assert_file()     { [[ -f "$1" ]] && _pass "$2" || _fail "$2 — 파일 없음: $1"; }
assert_no_file()  { [[ ! -f "$1" ]] && _pass "$2" || _fail "$2 — 존재하면 안 됨: $1"; }
assert_not_exists() { [[ ! -e "$1" ]] && _pass "$2" || _fail "$2 — 존재하면 안 됨: $1"; }

assert_symlink() {
    if [[ -L "$1" ]]; then
        local target; target=$(readlink "$1")
        [[ "$target" == *"$2"* ]] && _pass "$3" || _fail "$3 — symlink 대상 불일치: $target (expected *$2*)"
    else
        _fail "$3 — symlink 아님: $1"
    fi
}

assert_contains() {
    [[ -f "$1" ]] && grep -q "$2" "$1" && _pass "$3" || _fail "$3 — '$2' not found in $1"
}

assert_git() { [[ -d "$1/.git" ]] && _pass "$2" || _fail "$2 — .git 없음: $1"; }

# ─── 테스트 환경 ─────────────────────────────────────────────────────────────

# 최소 vault 생성 (install 테스트와는 별도)
_make_test_vault() {
    local vault="$TEST_ROOT/vault"
    mkdir -p "$vault/.vault"
    cat > "$vault/.vault/config.yaml" <<EOF
vault:
  path: "$vault"
  owner: "tester"
notion:
  enabled: false
  archive_db_id: ""
  archive_data_source_id: ""
projects: []
EOF
    touch "$vault/.vault/daily.conf"
    echo "$vault"
}

# 최소 git repo 생성
_make_git_repo() {
    local path="$1"
    mkdir -p "$path"
    (cd "$path" && git init --quiet && echo "init" > README.md && git add -A && git commit -m "init" --quiet)
}

# ─── 테스트 함수 ─────────────────────────────────────────────────────────────

test_install() {
    echo -e "\n${T_BLUE}━━━ TEST: _install_vault ━━━${NC}"

    local vault="$TEST_ROOT/vault-install"

    # Core 함수 직접 호출 — interactive 없음
    _install_vault "$vault" "test-owner" > /dev/null 2>&1

    assert_dir  "$vault/.vault"             ".vault/ 생성"
    assert_dir  "$vault/.vault/templates"   "templates/ 생성"
    assert_dir  "$vault/.vault/guides"      "guides/ 생성"
    assert_dir  "$vault/.vault/scripts"     "scripts/ 생성"
    assert_dir  "$vault/01_Global/daily"    "01_Global/daily/ 생성"
    assert_dir  "$vault/01_Global/literature" "01_Global/literature/ 생성"
    assert_dir  "$vault/ZZ_Temp/Claude"     "ZZ_Temp/Claude/ 생성"
    assert_file "$vault/CLAUDE.md"          "CLAUDE.md 복사"
    assert_file "$vault/.vault/config.yaml" "config.yaml 생성"
    assert_contains "$vault/.vault/config.yaml" "$vault"      "config: vault path"
    assert_contains "$vault/.vault/config.yaml" "test-owner"  "config: owner"
}

test_install_idempotent() {
    echo -e "\n${T_BLUE}━━━ TEST: _install_vault 재실행 (idempotent) ━━━${NC}"

    local vault="$TEST_ROOT/vault-idempotent"

    _install_vault "$vault" "owner1" > /dev/null 2>&1

    # 기존 config를 수동 수정
    echo "# custom" >> "$vault/.vault/config.yaml"

    # 재실행
    _install_vault "$vault" "owner2" > /dev/null 2>&1

    # config.yaml은 보존 (덮어쓰지 않음)
    assert_contains "$vault/.vault/config.yaml" "# custom" "config.yaml 보존 (덮어쓰지 않음)"
}

test_ensure_repo_git() {
    echo -e "\n${T_BLUE}━━━ TEST: _ensure_repo git ━━━${NC}"

    local repo="$TEST_ROOT/repos/new-git"

    _ensure_repo "$repo" "git" > /dev/null 2>&1

    assert_dir  "$repo"     "디렉토리 생성"
    assert_git  "$repo"     "git 초기화"
    assert_no_file "$repo/pyproject.toml" "pyproject.toml 없음"
}

test_ensure_repo_uv() {
    echo -e "\n${T_BLUE}━━━ TEST: _ensure_repo uv ━━━${NC}"

    if ! command -v uv &>/dev/null; then
        _skip "uv 미설치 — SKIP"
        return
    fi

    local repo="$TEST_ROOT/repos/new-uv"

    _ensure_repo "$repo" "uv" > /dev/null 2>&1

    assert_dir  "$repo"              "디렉토리 생성"
    assert_git  "$repo"              "git 초기화"
    assert_file "$repo/pyproject.toml" "pyproject.toml (uv init)"
}

test_ensure_repo_existing() {
    echo -e "\n${T_BLUE}━━━ TEST: _ensure_repo existing ━━━${NC}"

    local repo="$TEST_ROOT/repos/existing"
    _make_git_repo "$repo"
    echo "custom" > "$repo/custom.txt"

    _ensure_repo "$repo" "existing" > /dev/null 2>&1

    assert_file "$repo/custom.txt" "기존 파일 보존"
    assert_git  "$repo"            "git 유지"
}

test_setup_project_basic() {
    echo -e "\n${T_BLUE}━━━ TEST: _setup_project 기본 ━━━${NC}"

    local vault; vault=$(_make_test_vault)
    local repo="$TEST_ROOT/repos/proj-basic"
    _make_git_repo "$repo"

    _setup_project "$vault" "P010" "BasicTest" "기본 테스트" "$repo" > /dev/null 2>&1

    # 구조 확인
    assert_dir  "$repo/agent-docs/obsidian"              "agent-docs/obsidian/"
    assert_dir  "$repo/agent-docs/obsidian/foundations"   "foundations/"
    assert_dir  "$repo/agent-docs/obsidian/problems"     "problems/"
    assert_dir  "$repo/agent-docs/obsidian/engineering"   "engineering/"
    assert_dir  "$repo/agent-docs/obsidian/writing"       "writing/"
    assert_dir  "$repo/agent-docs/tasks"                  "tasks/"
    assert_dir  "$repo/agent-docs/analyze"                "analyze/"
    assert_file "$repo/agent-docs/obsidian/00_project_index.md" "프로젝트 인덱스"
    assert_file "$repo/CLAUDE.md"                         "CLAUDE.md"

    # Symlink
    assert_symlink "$vault/P010_BasicTest" "agent-docs/obsidian" "Vault symlink"

    # 플레이스홀더
    assert_contains "$repo/agent-docs/obsidian/00_project_index.md" "P010"      "플레이스홀더: PROJECT_ID"
    assert_contains "$repo/agent-docs/obsidian/00_project_index.md" "BasicTest" "플레이스홀더: PROJECT_NAME"

    # config.yaml
    assert_contains "$vault/.vault/config.yaml" "P010"  "config.yaml에 프로젝트"

    # daily.conf
    assert_contains "$vault/.vault/daily.conf" "$repo"  "daily.conf에 repo"
}

test_setup_project_existing_agent_docs() {
    echo -e "\n${T_BLUE}━━━ TEST: _setup_project 기존 agent-docs 보존 ━━━${NC}"

    local vault; vault=$(_make_test_vault)
    local repo="$TEST_ROOT/repos/proj-existing-docs"
    _make_git_repo "$repo"

    # 기존 agent-docs/obsidian/ 파일 생성
    mkdir -p "$repo/agent-docs/obsidian"
    echo "기존 내용" > "$repo/agent-docs/obsidian/existing.md"

    _setup_project "$vault" "P011" "ExistDocs" "기존 docs 테스트" "$repo" > /dev/null 2>&1

    assert_file "$repo/agent-docs/obsidian/existing.md"         "기존 파일 보존"
    assert_file "$repo/agent-docs/obsidian/00_project_index.md" "새 파일 추가"
    assert_dir  "$repo/agent-docs/obsidian/foundations"          "foundations/ 추가"
}

test_setup_project_existing_claude_md() {
    echo -e "\n${T_BLUE}━━━ TEST: _setup_project 기존 CLAUDE.md 보존 ━━━${NC}"

    local vault; vault=$(_make_test_vault)
    local repo="$TEST_ROOT/repos/proj-existing-claude"
    _make_git_repo "$repo"

    # 기존 CLAUDE.md
    echo "# My Custom Config" > "$repo/CLAUDE.md"

    _setup_project "$vault" "P012" "KeepClaude" "기존 CLAUDE.md 보존" "$repo" > /dev/null 2>&1

    assert_contains "$repo/CLAUDE.md" "My Custom Config" "CLAUDE.md 덮어쓰지 않음"
}

test_setup_project_vault_collision() {
    echo -e "\n${T_BLUE}━━━ TEST: _setup_project vault 충돌 감지 ━━━${NC}"

    local vault; vault=$(_make_test_vault)
    local repo1="$TEST_ROOT/repos/proj-collision1"
    local repo2="$TEST_ROOT/repos/proj-collision2"
    _make_git_repo "$repo1"
    _make_git_repo "$repo2"

    # 첫 번째 프로젝트 생성
    _setup_project "$vault" "P013" "Collision" "충돌 1" "$repo1" > /dev/null 2>&1

    # 같은 ID로 두 번째 시도 → 실패해야 함
    local result=0
    _setup_project "$vault" "P013" "Collision" "충돌 2" "$repo2" > /dev/null 2>&1 || result=$?

    [[ $result -ne 0 ]] && _pass "vault 충돌 시 실패 (exit $result)" \
                        || _fail "vault 충돌인데 성공해버림"
}

test_full_flow_uv() {
    echo -e "\n${T_BLUE}━━━ TEST: 전체 흐름 (uv init → setup_project) ━━━${NC}"

    if ! command -v uv &>/dev/null; then
        _skip "uv 미설치 — SKIP"
        return
    fi

    local vault; vault=$(_make_test_vault)
    local repo="$TEST_ROOT/repos/full-uv"

    _ensure_repo "$repo" "uv" > /dev/null 2>&1
    _setup_project "$vault" "P020" "FullUV" "전체 흐름 테스트" "$repo" > /dev/null 2>&1

    assert_file "$repo/pyproject.toml"                   "pyproject.toml"
    assert_git  "$repo"                                   "git repo"
    assert_dir  "$repo/agent-docs/obsidian/foundations"   "foundations/"
    assert_symlink "$vault/P020_FullUV" "agent-docs/obsidian" "Vault symlink"
    assert_contains "$vault/.vault/config.yaml" "P020"   "config.yaml"
}

test_full_flow_git() {
    echo -e "\n${T_BLUE}━━━ TEST: 전체 흐름 (git init → setup_project) ━━━${NC}"

    local vault; vault=$(_make_test_vault)
    local repo="$TEST_ROOT/repos/full-git"

    _ensure_repo "$repo" "git" > /dev/null 2>&1
    _setup_project "$vault" "P021" "FullGit" "전체 흐름 테스트" "$repo" > /dev/null 2>&1

    assert_no_file "$repo/pyproject.toml"                "pyproject.toml 없음"
    assert_git  "$repo"                                   "git repo"
    assert_dir  "$repo/agent-docs/obsidian"              "agent-docs/obsidian/"
    assert_symlink "$vault/P021_FullGit" "agent-docs/obsidian" "Vault symlink"
}

test_multiple_projects() {
    echo -e "\n${T_BLUE}━━━ TEST: 하나의 vault에 여러 프로젝트 ━━━${NC}"

    local vault; vault=$(_make_test_vault)

    for i in 1 2 3; do
        local repo="$TEST_ROOT/repos/multi-$i"
        _make_git_repo "$repo"
        _setup_project "$vault" "P03$i" "Multi$i" "멀티 $i" "$repo" > /dev/null 2>&1
    done

    assert_symlink "$vault/P031_Multi1" "agent-docs/obsidian" "프로젝트 1 symlink"
    assert_symlink "$vault/P032_Multi2" "agent-docs/obsidian" "프로젝트 2 symlink"
    assert_symlink "$vault/P033_Multi3" "agent-docs/obsidian" "프로젝트 3 symlink"
    assert_contains "$vault/.vault/config.yaml" "P031" "config: P031"
    assert_contains "$vault/.vault/config.yaml" "P032" "config: P032"
    assert_contains "$vault/.vault/config.yaml" "P033" "config: P033"
}

# ─── 테스트 목록 ─────────────────────────────────────────────────────────────
ALL_TESTS=(
    test_install
    test_install_idempotent
    test_ensure_repo_git
    test_ensure_repo_uv
    test_ensure_repo_existing
    test_setup_project_basic
    test_setup_project_existing_agent_docs
    test_setup_project_existing_claude_md
    test_setup_project_vault_collision
    test_full_flow_uv
    test_full_flow_git
    test_multiple_projects
)

list_tests() {
    echo "사용 가능한 테스트:"
    for t in "${ALL_TESTS[@]}"; do
        echo "  $t"
    done
}

# ─── 메인 ─────────────────────────────────────────────────────────────────────
main() {
    local selected_tests=()

    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose) VERBOSE=true ;;
            -l|--list)    list_tests; exit 0 ;;
            test_*)       selected_tests+=("$1") ;;
            *)            echo "알 수 없는 인자: $1"; exit 1 ;;
        esac
        shift
    done

    # 기본: 전체 테스트
    if [[ ${#selected_tests[@]} -eq 0 ]]; then
        selected_tests=("${ALL_TESTS[@]}")
    fi

    echo -e "${BOLD}━━━ setup.sh 통합 테스트 ━━━${NC}"
    echo "REPO_DIR: $REPO_DIR"

    # 임시 디렉토리
    TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/rv-test-XXXXXX")
    echo "TEST_ROOT: $TEST_ROOT"
    echo ""

    # 테스트 실행
    for test_fn in "${selected_tests[@]}"; do
        if declare -f "$test_fn" > /dev/null 2>&1; then
            "$test_fn"
        else
            echo -e "${RED}테스트 함수 없음: $test_fn${NC}"
            ((FAIL++))
        fi
    done

    # 결과
    echo ""
    echo -e "${BOLD}━━━ 결과 ━━━${NC}"
    echo -e "  ${GREEN}PASS${NC}: $PASS"
    echo -e "  ${RED}FAIL${NC}: $FAIL"
    echo -e "  ${YELLOW}SKIP${NC}: $SKIP"
    echo ""

    # 정리
    if $VERBOSE; then
        echo "  임시 파일 보존: $TEST_ROOT"
    else
        rm -rf "$TEST_ROOT"
        echo "  (임시 파일 정리 완료. -v로 보존 가능)"
    fi

    [[ $FAIL -gt 0 ]] && exit 1 || exit 0
}

main "$@"
