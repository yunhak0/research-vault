# Research Vault

Obsidian 기반 연구 문서 관리 시스템. 문제 중심(problem-centric) 구조로 연구 과정을 체계적으로 기록하고, Claude AI와 연동하여 일일 자동화·문서 생성·Notion 아카이빙을 지원합니다.

## 특징

- **문제 중심 구조**: 연구 문제(PRB) 단위로 탐구→학습→해결 과정을 추적
- **ID 기반 문서 체계**: FND, PRB, INV, LRN, RES, ENG, WRT, LIT 접두사로 문서 유형 구분
- **Claude AI 연동**: `CLAUDE.md` 설정으로 세션 정리, 일일 노트, 논문 리뷰 등 자동화
- **Claude Code Hooks**: 세션 자동 저장/복원, 전략적 compact 제안으로 코딩 에이전트 컨텍스트 관리
- **Ralph-Loop**: ralph-loop 플러그인으로 기계적 작업(테스트, 리팩토링, lint 수정)을 자율 반복 실행
- **Daily 자동화**: Git 커밋, Obsidian 변경, Claude 세션을 자동 수집하여 일일 연구 로그 생성
- **Notion 아카이빙**: 연구 결론을 Notion DB에 구조화하여 보관 (선택)
- **크로스 플랫폼**: macOS, Linux, WSL(Windows) 지원

## 요구사항

- **macOS / Linux** / **Windows**: 그대로 사용 가능

## 빠른 시작

```bash
# 1. 저장소 클론
git clone git@github.com:yunhak0/research-vault.git
cd research-vault

# 2. Vault 설치 (대화형)
bash setup.sh install

# 3. 첫 프로젝트 생성
bash setup.sh project

# 4. Daily 자동화 (install 시 건너뛴 경우)
bash setup.sh daily
```

## Vault 구조

설치 후 생성되는 vault 디렉토리:

```
my-vault/
├── CLAUDE.md                   ← Claude AI 설정 (vault 운영 가이드)
├── .vault/
│   ├── config.yaml             ← vault 전체 설정
│   ├── daily.conf              ← Git 추적 대상 저장소 목록
│   ├── templates/              ← 문서 템플릿 (12개)
│   ├── guides/                 ← 작성 가이드 (12개)
│   ├── scripts/                ← 자동화 스크립트
│   ├── skills/                 ← Claude AI 스킬 (SKILL.md 기반)
│   └── daily_data/             ← raw data (자동 생성)
├── 01_Global/
│   ├── daily/                  ← 일일 연구 로그 (DAILY-YYYY-MM-DD.md)
│   └── literature/             ← 논문 리뷰 (LIT-###_title.md)
├── P001_ProjectName/           ← symlink → repo의 agent-docs/obsidian/
│   ├── 00_project_index.md
│   ├── foundations/            ← 확립된 기반 결정 (FND-###)
│   ├── problems/               ← 문제 단위 연구 (PRB-###/)
│   ├── engineering/            ← 엔지니어링 개선 (ENG-###)
│   └── writing/                ← 논문 작성 (WRT-###)
└── ZZ_Temp/
    └── Claude/                 ← Claude 세션 요약
```

### 프로젝트 Repo 구조 (실체)

vault의 `P001_ProjectName/`은 프로젝트 repo의 `agent-docs/obsidian/`을 가리키는 symlink입니다.
프로젝트 repo 전체 구조:

```
~/github/P001_ProjectName/          ← 프로젝트 repo
├── CLAUDE.md                       ← 코딩 에이전트 설정
├── .claude/                        ← Claude Code hooks + settings
│   ├── hooks.json
│   ├── settings.json
│   └── hooks/                      ← Hook 구현체 (5개 .js)
├── src/                            ← 코드
└── agent-docs/
    ├── obsidian/                   ← 연구 문서 (vault에서 symlink으로 참조)
    │   ├── 00_project_index.md
    │   ├── foundations/
    │   ├── problems/
    │   ├── engineering/
    │   └── writing/
    ├── tasks/                      ← 코딩 에이전트 작업 추적 (todo.md + lessons.md)
    └── analyze/                    ← 분석 스크립트·결과
```

## 문서 체계

### ID 접두사

| 접두사 | 위치 | 설명 |
|--------|------|------|
| `FND-###` | `foundations/` | 확립된 기반 결정 |
| `PRB-###` | `problems/` (폴더) | 연구 문제 단위 |
| `INV-###` | `problems/PRB-###/investigating/` | 탐구 중인 분석 |
| `LRN-###` | `problems/PRB-###/learned/` | 기각된 시도, 교훈 |
| `RES-###` | `problems/PRB-###/resolved/` | 검증된 해결책 |
| `ENG-###` | `engineering/` | 엔지니어링 개선 |
| `WRT-###` | `writing/` | 논문 작성 |
| `LIT-###` | `01_Global/literature/` | 논문 리뷰 (프로젝트 독립) |

### 문제(PRB) 생명주기

```
문제 발견 → PRB-###/ 폴더 생성 + _overview.md
    ↓
탐구 → investigating/INV-###.md
    ↓
실패 → learned/LRN-###.md (교훈 기록)
    ↓
해결 → resolved/RES-###.md
    ↓
아카이빙 → _overview.md → Notion
```

## setup.sh 명령어

| 명령 | 설명 |
|------|------|
| `bash setup.sh install [경로]` | 새 vault 초기 구성. 디렉토리 생성, 파일 복사, config.yaml 설정 |
| `bash setup.sh project` | 프로젝트 추가. ID/이름 입력 → 폴더 생성 + 코드 저장소 연결 |
| `bash setup.sh daily` | Daily 자동화 설치. alias 등록 + Git 저장소 설정 |
| `bash setup.sh wandb` | W&B MCP 서버 설정. API key + Claude Code 연결 |
| `bash setup.sh obsidian` | Obsidian MCP 서버 설정. vault 경로 연결 |
| `bash setup.sh context7` | Context7 MCP 서버 설정. 라이브러리 문서 조회 |
| `bash setup.sh --help` | 도움말 |

## Daily 자동화

```bash
# 터미널에서
daily-start              # 어제 데이터 수집 + 오늘 빈 템플릿 생성
daily-update             # 어제 daily note에 누락분 추가
daily-update 2025-02-09  # 특정 날짜 업데이트

# Claude에서
"일일 시작"              # raw data → 구조화된 daily note 자동 생성
```

수집 대상: Claude 세션 파일, Obsidian vault 변경, Git 커밋 로그

## Claude 연동

`CLAUDE.md`가 vault 루트에 위치하며, Claude가 vault 구조와 워크플로우를 이해하는 데 사용됩니다.

### 트리거 키워드

| 키워드 | 동작 |
|--------|------|
| `세션 정리` | 현재 세션을 ZZ_Temp/Claude/에 요약 저장 |
| `일일 시작` | raw data → 구조화된 daily note 생성 |
| `논문 정리` | 논문 리뷰 문서 생성 (01_Global/literature/) |
| `문제 정리` | PRB 폴더 + _overview.md 생성 |

### config.yaml

빈 값(`""`)이나 빈 배열(`[]`)은 첫 Claude 세션에서 자동으로 질문됩니다.

```yaml
vault:
  path: ""                    # setup.sh가 자동 설정
  owner: ""                   # setup.sh가 자동 설정
notion:
  enabled: false              # Notion 연계 사용 여부
  archive_db_id: ""           # Notion Research Archive DB ID
  archive_data_source_id: ""  # Notion Data Source ID
projects: []                  # setup.sh project로 자동 관리
```

Git 저장소 추적 설정은 `.vault/daily.conf`에서 관리됩니다 (`setup.sh project` 실행 시 자동 추가).

### Notion 아카이브 설정

Notion 연계는 선택 기능입니다. 사용하려면 Notion MCP가 연결된 Claude 세션에서 다음과 같이 요청합니다:

**1단계: Research Archive DB 생성**

Claude에게 아래와 같이 요청합니다:

> "Notion에 Research Archive 데이터베이스를 만들어줘. 스키마는 다음과 같아:"

| Property | Type | 옵션 |
|----------|------|------|
| `Name` | Title | — |
| `ID` | Text | — |
| `Type` | Select | LIT, FND, PRB, WRT |
| `Status` | Select | Draft, In Progress, Completed, Validated, Rejected, Resolved |
| `Project` | Select | 프로젝트별 (e.g. P001_scDiffuser, Global) |
| `Tags` | Multi-select | 연구 키워드 (e.g. diffusion, single-cell, vae) |
| `Obsidian Path` | Text | — |
| `Related IDs` | Text | — |
| `Created` | Date | — |
| `Archived` | Date | — |

Project 옵션과 Tags 옵션은 자신의 연구 주제에 맞게 수정하세요.

**2단계: DB ID 확인**

Claude가 DB를 생성하면 응답에 `database_id`와 `data_source_id` (`collection://...`)가 포함됩니다.
Notion 페이지 URL에서도 확인 가능합니다:

```
https://www.notion.so/{database_id}?v={view_id}
                      ^^^^^^^^^^^^^^^^
                      이 부분이 archive_db_id
```

`data_source_id`는 Claude에게 "방금 만든 DB를 fetch해줘"라고 하면 `<data-source url="collection://...">`에서 확인할 수 있습니다.

**3단계: config.yaml 연결**

확인한 ID를 `.vault/config.yaml`에 입력합니다:

```yaml
notion:
  enabled: true
  archive_db_id: "c9b7c9e8-1b91-483c-a8a0-60c50710a8c2"       # 예시
  archive_data_source_id: "cf3a6be3-34a2-4284-a849-ac5b5967e743" # 예시
```

설정 완료 후 Claude 세션에서 `논문 아카이빙` 등의 키워드로 Obsidian 문서를 Notion에 아카이빙할 수 있습니다.
상세한 아카이빙 규칙은 `.vault/guides/notion_archive_guide.md`를 참조하세요.

## 선택적 MCP 서버

`setup.sh`에 포함된 wandb, obsidian, context7 외에도, 연구 분야에 따라 추가 MCP 서버를 연결할 수 있습니다.

| MCP 서버 | 용도 | 등록 명령 |
|----------|------|-----------|
| **Notion** | 연구 아카이빙 | `claude mcp add notion --scope user -- npx -y @anthropic/notion-mcp-server` |
| **bioRxiv** | 프리프린트 검색 | `claude mcp add bioRxiv --scope user -- npx -y @anthropic/biorxiv-mcp-server` |
| **PubMed** | 논문 검색 | `claude mcp add PubMed --scope user -- npx -y @anthropic/pubmed-mcp-server` |

Notion 아카이브 DB 설정은 아래 [Notion 아카이브 설정](#notion-아카이브-설정) 섹션을 참조하세요.

## Claude Code Hooks

`setup.sh project`로 프로젝트를 생성하면 `.claude/` (설정 + hooks 구현체 포함)가 자동으로 복사됩니다. Claude Code 세션의 컨텍스트 유지를 자동화하는 4개의 hook입니다.

> **출처**: [everything-claude-code](https://github.com/affaan-m/everything-claude-code) (Anthropic hackathon winner)에서 Python AI/ML 연구 워크플로우에 맞게 최소화하여 채택.

### Hooks 개요

| Hook | 시점 | 동작 |
|------|------|------|
| **Session Start** | 세션 시작 | 직전 세션 요약을 Claude 컨텍스트에 자동 주입 |
| **Session End** | 세션 종료 | JSONL transcript에서 tasks/files/tools 추출 → `~/.claude/sessions/`에 저장 |
| **Pre-Compact** | compact 직전 | 세션 파일에 "[Compaction occurred]" 마커 추가 |
| **Suggest Compact** | Edit/Write 50회마다 | `/compact` 고려를 stderr로 알림 |

### Token 최적화 설정

`.claude/settings.json`에서 비용 최적화 옵션을 설정합니다:

| 설정 | 기본값 | 설명 |
|------|--------|------|
| `model` | `sonnet` | 루틴 작업에 Sonnet 사용 (60% 비용 절감). Opus 필요 시 `--model opus` 오버라이드 |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `50` | 컨텍스트 50%에서 auto-compact (기본 95%보다 많이 여유로움) |
| `MAX_THINKING_TOKENS` | `10000` | Thinking 토큰 제한으로 비용 절감 |

### 파일 구성

```
your-project/
└── .claude/
    ├── settings.json              # 토큰 최적화
    ├── hooks.json                 # Hook 정의 (4개)
    └── hooks/                     # Hook 구현체 (Node.js, npm 불필요)
        ├── utils.js               # 공통 유틸리티
        ├── session-start.js       # 이전 세션 컨텍스트 로드
        ├── session-end.js         # 세션 요약 저장 (transcript 파싱)
        ├── pre-compact.js         # compact 전 상태 저장
        └── suggest-compact.js     # 전략적 compact 제안
```

### `agent-docs/tasks/` 파일과의 관계

Session hooks는 `CLAUDE.md`의 Task Management 워크플로우에서 정의하는 `agent-docs/tasks/todo.md`, `agent-docs/tasks/lessons.md`와 병행됩니다:

- **Session hooks** → 자동, 임시적. "지난번에 뭐 했는지" 요약을 Claude에 자동 주입
- **`agent-docs/tasks/todo.md`** → 수동, 지속적. 현재 작업 계획과 체크리스트
- **`agent-docs/tasks/lessons.md`** → 수동, 누적적. **구현** 관점의 교훈 (코딩 실수, 환경 이슈, 패턴)

> **구현 교훈 vs 연구 교훈**: `agent-docs/tasks/lessons.md`는 코딩 에이전트의 구현 교훈입니다.
> 연구 관점의 교훈(실험 결론, 기각 이유)은 `agent-docs/obsidian/problems/PRB-###/learned/`에 기록합니다.

### Ralph-Loop 연동

`/ralph-loop:ralph-loop` 실행 시 `tasks/`와 `prompts/`가 함께 작동합니다:

```
prompts/fix-something.md   ← 작업 지시서 (사람이 작성)
    ↓
/ralph-loop:ralph-loop "지시서대로 실행, todo.md에 진행 기록"
    ↓
tasks/todo.md              ← 체크리스트 자동 업데이트
tasks/lessons.md           ← 실패 시 교훈 기록
```

### 커스터마이징

- **Compact 임계값 변경**: `.claude/settings.json`의 `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` 값 수정
- **넘지 간격 변경**: 환경변수 `COMPACT_THRESHOLD=100`으로 오버라이드
- **Hooks 비활성화**: `.claude/hooks.json`에서 해당 hook 제거

## Ralph-Loop (자율 반복 루프)

`setup.sh project` 실행 시 [ralph-loop](https://github.com/anthropics/claude-code) 플러그인이 자동 설치됩니다. Claude Code가 작업 완료 후 종료하려 할 때 Stop hook이 exit를 가로채고, 같은 프롬프트를 다시 주입하여 완료될 때까지 반복 실행합니다.

### 사용법

```bash
/ralph-loop:ralph-loop "작업 지시" --max-iterations N --completion-promise "DONE"
```

| 파라미터 | 역할 | 권장 |
|---------|------|------|
| `--max-iterations` | 안전장치. 무한 루프 방지 | 15~30으로 시작 |
| `--completion-promise` | 이 문자열이 출력되면 종료 | `<promise>DONE</promise>` 패턴 |

### 실전 예시

**tasks/todo.md 기반 자동 실행** — `CLAUDE.md`의 "Plan → Track → Verify" 워크플로우와 가장 자연스럽게 맞물리는 패턴:

```
/ralph-loop:ralph-loop "Read tasks/todo.md. Pick the next unchecked item.
Implement it following CLAUDE.md principles.
Run tests to verify. Mark it done in todo.md.
If all items done, output <promise>PLAN_COMPLETE</promise>.
If stuck after 3 attempts on one item, document blockers and move to next."
--max-iterations 25 --completion-promise "PLAN_COMPLETE"
```

**Lint/타입 에러 일괄 수정:**

```
/ralph-loop:ralph-loop "Run ruff check . and fix all errors one by one.
After fixing, re-run ruff.
Output <promise>CLEAN</promise> when ruff reports 0 issues."
--max-iterations 15 --completion-promise "CLEAN"
```

**대규모 리팩토링:**

```
/ralph-loop:ralph-loop "Migrate all config loading from argparse to hydra/omegaconf.
Run existing tests after each file change.
Output <promise>MIGRATION_COMPLETE</promise> when all configs migrated and tests pass."
--max-iterations 30 --completion-promise "MIGRATION_COMPLETE"
```

### 적합한 작업 vs 부적합한 작업

| 적합 (기계적·반복적·검증 가능) | 부적합 (판단 중심) |
|------|------|
| 테스트 커버리지 확대 | 실험 설계 논의 |
| 리팩토링·마이그레이션 | 결과 해석·분석 방향 |
| Lint/타입 에러 일괄 수정 | 아키텍처 설계 결정 |
| todo.md 체크리스트 소화 | 논문 아이디어 brainstorming |

### 기존 Hooks와의 관계

Ralph-loop의 Stop hook은 기존 Session/Compact hooks와 충돌 없이 공존합니다:

```
research-vault hooks (기존)        ralph-loop (추가)
├── SessionStart  → 세션 복원       ├── Stop hook → exit 가로채기
├── SessionEnd    → 세션 저장        └── /ralph-loop:ralph-loop 명령어
├── PreCompact    → compact 전 저장
└── PreToolUse    → compact 제안
```

### 주의사항

자율 루프는 토큰을 많이 소모합니다 (50 iteration ≈ $50~100+). `--max-iterations`를 보수적으로 설정하고, 프롬프트에 "stuck하면 문서화하고 다음으로 넘어가라" 같은 탈출 조건을 넣으세요. 처음엔 수동으로 한 번씩 돌려보며 감을 잡은 다음 자동화하는 것을 권장합니다.

Claude Code CLI가 없는 환경에서는 첫 세션에서 `/plugin install ralph-loop@claude-plugins-official`로 수동 설치하세요.

## Skills

`.vault/skills/`에 SKILL.md 기반의 Claude AI 스킬을 배치할 수 있습니다. 스킬은 특정 작업에 대한 Claude의 동작 패턴을 정의하는 파일로, 트리거 조건과 구체적 절차를 포함합니다.

### 스킬 vs 모드 vs Hooks

| | 스킬 (`.vault/skills/`) | 모드 (`CLAUDE.md`) | Hooks (`.claude/hooks.json`) |
|---|---|---|---|
| **범위** | 특정 작업 패턴 | 응답 관점/페르소나 | 세션 생명주기 이벤트 |
| **호출** | 명시적 또는 키워드 기반 | 컨텍스트에서 자동 추론 | 이벤트 발생 시 자동 실행 |
| **예시** | 발표 슬라이드 생성 | Biology/AI/Reviewer/Scribe | 세션 저장, compact 제안 |
| **환경** | claude.ai, Claude Code 모두 | claude.ai (이 vault) | Claude Code CLI |

### 현재 등록된 스킬

없음. `tasks/lessons.md`에 동일 교훈이 3회 이상 누적되면 스킬로 추출합니다.

### 스킬 생성 가이드

스킬은 반복적으로 수행하는 작업이 패턴화될 때 만듭니다. `tasks/lessons.md`에 동일 교훈이 3회 이상 누적되면 스킬로 추출할 후보입니다.

새 스킬 작성 시 필수 구성:

```
.vault/skills/{skill-name}/
├── SKILL.md          ← name, description (frontmatter) + 트리거 조건, 절차, 입출력 사양
└── references/       ← (선택) 상세 가이드, 디자인 사양 등
```

상세 작성법과 Lesson→Skill 추출 워크플로우: `.vault/guides/skill_creation_guide.md` 참조.

---

## 저장소 구조

```
research-vault/
├── setup.sh                    ← 설치 스크립트 (진입점)
├── README.md                   ← 이 문서
├── vault_core/                 ← vault에 복사되는 핵심 파일
│   ├── CLAUDE.md
│   ├── .claude/                ← Claude Code 설정 (settings + hooks)
│   ├── config.yaml
│   ├── daily.conf
│   ├── templates/  (12개)
│   ├── guides/     (12개)
│   └── scripts/    (4개)
├── tests/                      ← 개발용 테스트 (배포 제외)
│   ├── test_setup.sh           ← setup.sh 통합 테스트
│   └── TASK-test-setup.md      ← 테스트 실행 가이드
└── project_template/           ← 프로젝트 생성 시 복사되는 템플릿
    ├── CLAUDE.md               ← 코딩 에이전트 설정 (Bootstrap 패턴)
    ├── .claude/
    │   ├── settings.json       ← 토큰 최적화 (모델, compact 임계값)
    │   ├── hooks.json          ← Hook 정의 (4개)
    │   └── hooks/              ← Hook 구현체 (Node.js)
    │       ├── utils.js
    │       ├── session-start.js
    │       ├── session-end.js
    │       ├── pre-compact.js
    │       └── suggest-compact.js
    ├── README.md               ← 프로젝트 문서 정의서 (agent-docs/obsidian/으로 복사됨)
    └── agent-docs/
        ├── obsidian/               ← 연구 문서 (vault symlink 대상)
        │   ├── 00_project_index.md
        │   ├── foundations/
        │   ├── problems/
        │   ├── engineering/
        │   └── writing/
        ├── tasks/                  ← 코딩 에이전트 작업 추적 (todo.md + lessons.md)
        └── analyze/                ← 분석 스크립트·결과
```

## 요구사항

- **bash** 4.0+
- **Git** (daily 자동화에 필요)
- **jq** (Claude Code vault hook에 필요)
- **Node.js** (Claude Code hooks에 필요 — Claude Code 설치 시 이미 포함)
- **Obsidian** (권장, 다른 마크다운 에디터도 가능)
- **Claude** (AI 연동 기능 사용 시)
- **Claude Code** (hooks 기능 사용 시, 선택)

## 라이선스

MIT
