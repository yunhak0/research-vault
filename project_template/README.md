# {{PROJECT_ID}}_{{PROJECT_NAME}} — 연구 문서 정의서

> {{PROJECT_DESCRIPTION}}
> 이 문서는 프로젝트의 연구 문서 구조, ID 체계, 워크플로우, Notion 연계 방식을 정의한다.
> 위치: 프로젝트 repo의 `agent-docs/obsidian/` 안에 존재하며, vault에서는 symlink을 통해 접근한다.

---

## 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **프로젝트** | {{PROJECT_NAME}} — {{PROJECT_DESCRIPTION}} |
| **핵심 아키텍처** | {{ARCHITECTURE_SUMMARY}} |
| **코드** | 이 repo의 루트 (또는 해당 코드 디렉토리) |
| **연구 문서** | 이 repo의 `agent-docs/obsidian/` (vault에서 symlink으로 접근) |
| **W&B** | {{WANDB_PROJECT}} |
| **Notion Archive** | vault `config.yaml → notion.archive_db_id` 참조 |

> **Note**: `{{...}}` 플레이스홀더는 프로젝트 생성 시 `setup.sh project` 명령 또는 첫 Claude 세션에서 실제 값으로 교체됩니다.
> **구조**: 프로젝트 repo가 code + docs를 모두 소유. vault는 이 repo를 symlink으로 참조한다. Server에서 git pull하면 agent-docs/에 즉시 접근 가능.

---

## agent-docs/ 폴더 구조

```
agent-docs/
├── obsidian/                                ← vault에서 symlink되는 연구 문서
│   ├── foundations/                      ← 확립된 기반 결정
│   │   └── FND-001_xxx.md
│   │
│   ├── problems/                        ← 문제 단위 연구 기록
│   │   ├── PRB-001_xxx/
│   │   │   ├── _overview.md             ← 결론 요약서 + 링크 허브
│   │   │   ├── learned/                 ← 시도했으나 기각/실패
│   │   │   │   └── LRN-001_xxx.md
│   │   │   ├── investigating/           ← 현재 탐구 중
│   │   │   │   └── INV-001_xxx.md
│   │   │   ├── resolved/                ← 검증 완료된 해결책
│   │   │   │   └── RES-001_xxx.md
│   │   │   └── prompts/                 ← 코딩 프롬프트 (해당 문제용)
│   │   └── PRB-002_xxx/
│   │       └── ...
│   │
│   ├── engineering/                      ← 엔지니어링 기술 개선
│   │   └── ENG-001_xxx.md
│   │
│   ├── writing/                         ← 논문 작성용 draft
│   │   └── WRT-001_xxx.md
│   │
│   └── 00_project_index.md              ← 자동 생성 프로젝트 인덱스
│
├── tasks/                               ← 코딩 에이전트 작업 관리
│   ├── prompts/                         ← 구현 프롬프트
│   ├── todo.md                          ← 작업 체크리스트
│   └── lessons.md                       ← 구현 교훈 DB
│
└── analyze/                             ← 분석 스크립트/리포트
    └── ...
```

---

## 폴더 정의

### `foundations/`

**목적**: 프로젝트 전체에 적용되는 아키텍처·방법론의 확립된 결정을 기록한다. 특정 문제의 해결이 아니라, 프로젝트의 기본 전제로 확정된 사항이 대상이다.

**진입 조건**: 실험적으로 검증 완료되어 더 이상 논쟁의 여지가 없는 것.

**예시**: 핵심 아키텍처 채택 근거 및 검증 결과, 입출력 정규화 파이프라인 결정.

| 항목 | 값 |
|------|-----|
| ID 접두사 | `FND-###` |
| Notion 아카이빙 | 개별 문서 단위, Type=`FND` |

### `problems/`

**목적**: 연구 과정에서 마주한 문제를 정의·진단·해결하는 전체 흐름을 문제 단위로 관리한다. 하나의 문제 = 하나의 폴더.

| 항목 | 값 |
|------|-----|
| ID 접두사 | `PRB-###` (폴더명) |
| 내부 구조 | `_overview.md` + 성숙도별 서브폴더 |
| Notion 아카이빙 | `_overview.md` 기준, 문제 단위, Type=`PRB` |

#### 서브폴더

| 서브폴더 | ID 접두사 | 정의 | 들어가는 것 |
|----------|-----------|------|------------|
| `investigating/` | `INV-###` | 현재 탐구 중인 가설·분석·진단 | 진단 계획, 실험 중간 분석, 미확정 가설 |
| `learned/` | `LRN-###` | 시도했으나 기각되거나 실패한 것. 교훈이 핵심 | 실패한 접근의 상세 기록, 왜 안 됐는지의 분석 |
| `resolved/` | `RES-###` | 검증 완료된 해결책 | 최종 실험 결과, 확정된 구성, 성공한 접근 |
| `prompts/` | — | 코딩 에이전트용 프롬프트 | 해당 문제 해결을 위한 구현 지시서 |

#### `_overview.md`

문제 폴더의 **결론 요약서**이자 **링크 허브**. 이 파일이 Notion에 아카이빙되는 단위이다.

**내용 구조**:
- **결론**: 한눈에 파악할 수 있는 1~2 문단 요약
- **핵심 발견**: 번호 리스트, 각 항목에 근거 문서 wikilink
- **기각된 접근**: 표 형태 (시도 | 왜 안 됐나 | 근거 문서 링크)
- **확정 구성**: 최종 하이퍼파라미터, loss, 정량 결과
- **후속 영향**: 다른 문제나 다음 단계에 미친 영향

**작성 시점**:
- Investigating 단계: 현황 요약으로 유지 (문제 정의, 현재 진행 상황)
- Resolved 시: 결론 중심으로 최종 작성 → Notion 아카이빙

### `engineering/`

**목적**: 프로젝트의 **코드 품질·성능·유지보수성**을 개선하는 엔지니어링 작업을 기록한다. 연구 목표(왜 이런 결과가 나오는가?)와 직접 결합되지 않는, 순수 기술적 개선이 대상이다. 논문 Methods/Results에는 들어가지 않는 작업을 다룬다.

**PRB와의 구분 기준**: "이 작업의 결과가 논문에 들어가는가?" — Yes → FND 또는 PRB, No → ENG.

**대상 예시**: 데이터 파이프라인 성능 최적화, 코드 리팩토링, HPC/컨테이너 환경 설정, CI/CD.

| 항목 | 값 |
|------|-----|
| ID 접두사 | `ENG-###` |
| 구조 | 단일 문서 (PRB처럼 서브폴더 없음) |
| Notion 아카이빙 | 개별 문서 단위, Type=`ENG` (선택적) |

### `writing/`

**목적**: 논문·보고서 작성을 위한 draft 공간.

| 항목 | 값 |
|------|-----|
| ID 접두사 | `WRT-###` |
| 비고 | 연구가 충분히 진행된 후 본격 사용 |

---

## tasks/ 폴더 (agent-docs/obsidian/ 외부)

> `tasks/`는 `agent-docs/` 안에 위치하며, 코딩 에이전트의 작업 관리를 담당한다.

### `tasks/prompts/`

**목적**: Claude Desktop에서 설계한 구현 요청을 서버 Claude Code에 전달하는 핸드오프 문서를 보관한다.

**워크플로우**:
1. Claude Desktop에서 연구 분석·설계를 마친다
2. `tasks/prompts/PROMPT-###_{slug}.md`로 구현 프롬프트를 작성한다
3. `tasks/todo.md`에 해당 항목을 추가한다
4. 사용자가 `git push` → 서버 Claude Code가 읽고 구현한다

| 항목 | 값 |
|------|-----|
| 위치 | `agent-docs/tasks/prompts/` |
| 파일명 | `PROMPT-###_{slug}.md` |
| 상태 | `Pending` → `In Progress` → `Done` / `Cancelled` |
| 템플릿 | vault의 `.vault/templates/task_prompt.md` |

> **문제별 프롬프트와의 구분**: 특정 PRB에 종속된 구현은 `agent-docs/obsidian/problems/PRB-###/prompts/`에, 프로젝트 전체에 걸치는 구현(리팩토링, 인프라 등)은 여기에 작성한다.

### `tasks/todo.md`

현재 작업 계획과 체크리스트. Claude Code가 세션 시작 시 읽고 다음 작업을 판단한다.

### `tasks/lessons.md`

구현 관점의 교훈 누적 데이터베이스. 연구 관점의 교훈(실험 결론, 기각 이유)은 `agent-docs/obsidian/problems/PRB-###/learned/`에 기록한다.

---

## analyze/ 폴더 (agent-docs/obsidian/ 외부)

> `analyze/`는 `agent-docs/obsidian/`과 달리 `agent-docs/` 하위에 위치한다.

### `analyze/`

**목적**: 서버 Claude Code가 실행하는 분석 스크립트, 결과, 리포트를 저장한다. Git으로 동기화되어 Local↔Server 간 자동 공유된다.

**대상 예시**:
- 실험 결과 분석 스크립트 (metrics 추출, 시각화)
- 진단 도구 (모델 체크포인트 검사, 데이터 품질 검증)
- 자동 생성 리포트 (W&B 데이터 요약, 비교 분석)

**PRB/ENG와의 구분**:
- `agent-docs/obsidian/problems/`, `agent-docs/obsidian/engineering/`는 **연구 문서** (왜, 무엇을, 어떻게 — Markdown 중심)
- `analyze/`는 **실행 가능한 코드** (분석 자동화 — Python/Shell 스크립트 중심)

| 항목 | 값 |
|------|-----|
| 위치 | `agent-docs/analyze/` (`agent-docs/obsidian/`과 동급) |
| 동기화 | Git (Local↔Server 자동) |
| 접근 | 서버 Claude Code가 직접 실행 가능 |
| ID 체계 | 없음 (코드 파일이므로 자유 명명) |

---

## ID 체계

### 프로젝트 내부 문서

| 접두사 | 위치 | 설명 |
|--------|------|------|
| `FND-###` | `foundations/` | 확립된 기반 결정 |
| `PRB-###` | `problems/` (폴더명) | 문제 단위 |
| `INV-###` | `problems/PRB-###/investigating/` | 탐구 중인 분석/가설 |
| `LRN-###` | `problems/PRB-###/learned/` | 기각된 시도, 교훈 |
| `RES-###` | `problems/PRB-###/resolved/` | 확정된 해결책 |
| `ENG-###` | `engineering/` | 엔지니어링 개선 |
| `WRT-###` | `writing/` | 논문 작성 문서 |

### 프로젝트 외부 문서 (참고)

| 접두사 | 위치 | 설명 |
|--------|------|------|
| `LIT-###` | `01_Global/literature/` | 논문 리뷰 (프로젝트 독립) |
| `DAILY-YYYY-MM-DD` | `01_Global/daily/` | 일일 연구 로그 |

**번호 규칙**: 각 접두사 내에서 독립적으로 001부터 순차 부여.

---

## 문서 생명주기

```
문제 발견
  │
  ├─→ PRB-###/ 폴더 생성
  │   _overview.md 작성 (문제 정의, 현황 요약)
  │   investigating/ 에 탐구 문서 작성
  │
  ├─→ 시도 & 실패
  │   investigating/ 문서를 learned/ 로 이동
  │   교훈 중심으로 내용 정리
  │
  ├─→ 해결
  │   resolved/ 에 최종 결과 문서 작성
  │   _overview.md 를 결론 중심으로 최종 작성
  │
  └─→ 아카이빙
      _overview.md 내용 → Notion 페이지 생성
      frontmatter에 notion_url 기록
```

### 문서 상태 (status)

| 상태 | 의미 | 사용 맥락 |
|------|------|----------|
| `Draft` | 초기 작성, 미완성 | 모든 문서 초기 상태 |
| `In Progress` | 활발히 작업 중 | INV 문서, 작성 중인 분석 |
| `Completed` | 작성 완료, 결론 도출 | LRN, RES 문서 |
| `Validated` | 실험으로 검증 확인 | FND, RES 문서 |
| `Rejected` | 기각됨 (사유 포함) | LRN 문서 (기각된 가설) |
| `Investigating` | 문제 미해결, 조사/실험 진행 중 | `_overview.md` 전용 |
| `Resolved` | 문제 해결 완료 | `_overview.md` 전용 |

---

## Notion 연계

> Notion 연계를 사용하지 않으면 이 섹션은 무시해도 됩니다.
> `config.yaml`에서 `notion.enabled: false`로 설정하세요.

### 역할 분담

| | Obsidian | Notion |
|---|---|---|
| **성격** | 작업 공간 (과정 중심) | 결론 저장소 (결과 중심) |
| **문서 수** | 문제당 3~5개 (상세 과정) | 문제당 **1개** (결론 요약) |
| **내용** | 진단 과정, 실험 설계, 시행착오 전부 | "결국 뭘 알게 됐는가" |
| **독자** | 작업 중인 나 | 나중의 나, 또는 동료 |

Notion은 아카이빙 장소이자 **최종 Summary 장소**이다. Obsidian 메모를 그대로 복사하는 것이 아니라, 모든 과정을 거친 뒤 도출된 결론을 정리하여 보관한다.

### Notion DB: Research Archive

| 속성 | 설명 |
|------|------|
| **DB ID** | `config.yaml → notion.archive_db_id` |
| **Data Source** | `config.yaml → notion.archive_data_source_id` |
| **Type 옵션** | `LIT`, `FND`, `PRB`, `ENG`, `WRT` |
| **Status 옵션** | `Draft`, `In Progress`, `Completed`, `Validated`, `Rejected`, `Investigating`, `Resolved`, `Key Paper` |
| **Project 옵션** | `config.yaml → projects[]` 에서 자동 |

### 아카이빙 대상

| Obsidian 문서 | Notion Type | 아카이빙 단위 | 설명 |
|--------------|-------------|-------------|------|
| `_overview.md` | `PRB` | 문제 단위 | 결론 요약서. wikilink → 텍스트 변환 |
| `FND-###.md` | `FND` | 개별 문서 | 기반 결정 요약 |
| `ENG-###.md` | `ENG` | 개별 문서 | 엔지니어링 개선 (선택적) |
| `LIT-###.md` | `LIT` | 개별 문서 | 논문 리뷰 |
| `learned/`, `resolved/`, `investigating/` 내 개별 문서 | — | **아카이빙하지 않음** | `_overview.md`에 결론이 요약되어 있으므로 |

### 아카이빙 워크플로우

1. 문제 Resolved (또는 FND 확정)
2. `_overview.md` 최종 작성: 결론 + 핵심 발견 + 기각 접근 + 확정 구성 + 후속 영향, 모든 하위 문서를 wikilink로 참조
3. Notion에 페이지 생성:
   - Type: `PRB` (또는 `FND`, `LIT`)
   - 내용: `_overview.md` 기반, wikilink를 "참조: LRN-001" 텍스트로 변환
   - Properties: ID, Status, Project, Obsidian Path, Created, Archived, Tags
4. Obsidian `_overview.md` frontmatter에 `notion_url` 기록
5. Obsidian 원본 전부 유지 (삭제 없음)

### Notion 페이지 구조 (PRB 타입 예시)

```
제목: PRB-001 문제명 — Resolution Summary

Properties:
  Type: PRB | Status: Resolved | Project: {{PROJECT_NAME}}
  ID: PRB-001 | Obsidian Path: {{PROJECT_ID}}_{{PROJECT_NAME}}/problems/PRB-001_.../
  Created: (생성일) | Archived: (아카이빙 일자)

Content:
  ## 결론
  (핵심 결론 1~2 문단)

  ## 핵심 발견
  (번호 리스트, 근거 문서명 텍스트 표기)

  ## 기각된 접근
  (표: 시도 | 왜 안 됐나 | 근거 문서)

  ## 확정 구성
  (최종 하이퍼파라미터, loss, 결과 수치)

  ## 후속 영향
  (다른 문제나 다음 단계에 미친 영향)
```

---

## 참고: 프로젝트 외부 리소스

| 경로 | 용도 |
|------|------|
| `{VAULT_PATH}/01_Global/literature/` | 논문 리뷰 (`LIT-###`). 프로젝트와 무관하게 독립 관리, wikilink로 참조 |
| `{VAULT_PATH}/01_Global/daily/` | 일일 연구 로그. 프로젝트 횡단 |
| `{VAULT_PATH}/.vault/templates/` | 문서 템플릿 (vault 내부) |
| `{VAULT_PATH}/.vault/guides/` | 문서 작성 가이드 (vault 내부) |

---

## Last Updated
- **Date**: {{CREATED_DATE}}
- **Changes**: 프로젝트 초기 생성
