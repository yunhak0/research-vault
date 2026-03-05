---
guide_for: claude_session
version: 3.0
last_updated: 2026-02-22
---

# Claude 세션 핸드오프 문서 작성 가이드

## 1. 목적

Claude 세션의 모든 맥락과 작업 상태를 **self-contained 문서**로 기록하여:
- **Context compaction 시 복원 지점**으로 사용
- 새로운 agent가 이 파일 **하나만 읽고** 모든 작업을 이어갈 수 있도록 보장
- Daily note 자동 생성 시 입력 데이터로 활용
- 주요 결정사항과 산출물 추적

> **핵심 원칙**: 이 문서를 읽는 새 agent는 이전 대화 히스토리에 접근할 수 없다. 따라서 이 문서가 대화 히스토리를 대체해야 한다.

## 2. ID 규칙

```
CLAUDE-[YYYY-MM-DD]-[summary-title]

summary-title = 세션 핵심 주제를 2-5 단어 영어 slug로 표현
예시:
  CLAUDE-2026-02-22-gene-level-diagnostic-plan
  CLAUDE-2026-02-16-vault-restructure
  CLAUDE-2026-02-19-metric-backward-compat
  CLAUDE-2026-02-12-sinkhorn-loss-review
```

**slug 작성 규칙**:
- 영어 소문자, 단어 사이 하이픈(-) 사용
- 프로젝트명이나 PRB 번호보다 **작업 내용**을 반영
- 같은 날 여러 세션이면 각각 다른 slug 사용

## 3. 파일 위치

```
ZZ_Temp/Claude/CLAUDE-[YYYY-MM-DD]-[summary-title].md
```

## 4. 작성 타이밍

- 세션 **종료 시** — 사용자가 `세션 정리`를 요청하거나 세션을 마무리할 때
- **Context compaction 직전** — 컨텍스트 용량이 부족해지면 즉시 작성
- **주제 전환 시** — 하나의 세션이 여러 독립 주제를 다루면 주제별로 분리 가능
- 짧은 질문/답변 세션은 기록 불필요

## 5. 섹션별 작성 규칙

### 5.1 세션 목적
- 1-2문장으로 세션의 주요 목적 기술
- "무엇을 하려고 Claude를 사용했는가"

### 5.2 배경 컨텍스트 ⭐ (핵심 섹션)

**이 섹션이 self-contained 문서의 핵심이다.** 새 agent가 프로젝트 히스토리를 모르는 상태에서 읽는다고 가정하고 작성한다.

포함해야 할 내용:
- **프로젝트 현황**: 무슨 프로젝트인지, 현재 어떤 단계인지, 핵심 아키텍처/접근법
- **선행 작업 결론**: 이 세션의 작업과 관련된 이전 결정사항, 핵심 수치 (e.g., "Cell-level Spearman GT≥4에서 Oracle 112% 달성")
- **미해결 상태**: 이 세션 시작 시점의 열린 문제들

**나쁜 예**: "지난 세션에서 논의한 대로..."
**좋은 예**: "PRB-002는 cell-level Spearman이 0.382로 낮아 보이는 문제를 진단하는 과정이다. Phase 0에서 GT≥4 구간 Oracle bound (0.535) 대비 모델이 112% (0.599)를 달성하여 cell-level은 해결했으나, gene-level이 Oracle의 16-25%에 불과한 새 문제를 발견한 상태이다."

### 5.3 관련 파일 위치

새 agent가 `read_file`로 바로 접근할 수 있도록 **절대 경로 또는 vault 내 상대 경로**를 테이블로 정리:

```markdown
| 파일 | 경로 | 설명 |
|------|------|------|
| PRB-002 overview | `P001_scDiffuser/docs/problems/PRB-002_spearman_gap/_overview.md` | Phase 1 계획 기록 |
| Oracle 코드 | `P001_scDiffuser/dev-code/scripts/oracle_bound.py` | Gene-level Oracle 계산 |
| W&B run | `yunhak/scdiffuser_1/xru1my9e` | 1a 모델, 최신 metric |
```

코드 파일, vault 문서, W&B run 경로, 설정 파일 등 세션에서 참조한 모든 것을 포함.

### 5.4 주요 작업 내용
- 실제 수행한 작업 나열
- **구체적으로**: 파일명, 함수명, 모델명, metric 값 등 포함
- 코드를 수정했다면 어떤 코드를 어떻게 바꿨는지 핵심만 포함
- W&B 분석을 했다면 핵심 수치를 테이블로 정리

### 5.5 핵심 논의 / 결정사항
- 중요한 설계 결정, 방향 전환, 인사이트
- 각 결정에 대해 **"무엇"과 "왜"** 모두 포함
- "왜 이렇게 결정했는가"를 생략하면 새 agent가 같은 논의를 반복하게 된다

### 5.6 생성/수정된 산출물
- 코드 파일, Obsidian 노트, 설정 파일 등
- 테이블 형식: 파일 경로 + 변경 내용

### 5.7 미해결 / 후속 작업 ⭐ (실행 가능한 프롬프트)

단순 TODO 리스트가 아니라 **새 agent가 바로 실행할 수 있는 수준의 상세 프롬프트**를 작성한다.

**나쁜 예**:
```
- Oracle bound 분석 추가 실행
- 결과에 따른 계획 조정
```

**좋은 예**:
```
### 즉시 실행 가능 (Phase 1 Step 1-2)

**oracle_bound.py 확장 — gene sparsity bin별 Oracle 분석**:
1. `compute_gene_level_oracle()` 함수 내에서 gene별 nonzero fraction 계산
2. Gene을 nonzero fraction bin으로 그룹화 (<10%, 10-30%, 30-50%, 50%+)
3. Bin별 Oracle gene-level Pearson/Spearman 계산
4. 실행: `python oracle_bound.py --gene-sparsity-analysis`

**기대 결과**: Sparse gene에서 Oracle이 이미 낮으면 구조적 문제, Oracle은 높은데 모델만 낮으면 진짜 한계

### Step 2 결과에 따라 (조건부)

- Dense gene에서 Oracle 초과 → WRT-001 v4에 gene-level defense 추가
- Dense gene에서도 Oracle의 ~50% 이하 → Sinkhorn OT loss 검토
```

**구성 패턴**:
- `### 즉시 실행 가능` — 조건 없이 바로 시작할 수 있는 작업
- `### 조건부 / 판단 필요` — 이전 단계 결과에 따라 분기하는 작업. 판단 기준을 명시

### 5.8 관련 문서
- Obsidian wiki-link with semantic prefixes (🔬 Supports, ⚡ Contradicts, 🔗 Extends, 🛠 Implements, ✅ Validates, ❌ Invalidates, 📎 Related)

## 6. Context Compaction 시나리오

Claude Code에서 context compaction이 발생하면:

1. **Compaction 전**: `세션 정리`를 먼저 실행하여 현재까지의 모든 맥락을 저장
2. **Compaction 후**: 새 agent는 `.CLAUDE.md`를 읽고, 가장 최근 `ZZ_Temp/Claude/CLAUDE-*.md` 파일을 찾아 읽어 맥락을 복원
3. **`배경 컨텍스트`** 섹션이 소실된 대화 히스토리를 대체하는 핵심 구간
4. **`미해결 / 후속 작업`** 섹션이 다음 행동을 즉시 결정할 수 있게 해주는 구간

> **Tip**: Compaction이 예상되면 평소보다 `배경 컨텍스트`를 더 상세하게 작성할 것.

## 7. Daily Note와의 관계

| Claude 세션 핸드오프 | Daily Note 자동 생성 |
|---------------------|-------------------|
| 원본 데이터 | 가공/요약된 결과 |
| 세션별 상세 기록 | 하루 전체 통합 요약 |
| ZZ_Temp/Claude/ | 01_Global/daily/ |

`daily-start` 실행 시 해당 날짜의 모든 Claude 세션 파일을 자동 수집하여 daily note에 반영.

## 8. 작성 예시

```markdown
---
doc_id: CLAUDE-2026-02-22-gene-level-diagnostic-plan
title: "Gene-level 저성능 진단 — W&B 분석, 코드 검증, Phase 1 계획 수립"
created: 2026-02-22
tags: [claude-session, gene-level, spearman, diagnostic, PRB-002]
project: P001_scDiffuser
status: Completed
related_docs: ["[[PRB-002_spearman_gap/_overview]]", "[[WRT-001_spearman_gap_defense]]"]
---

# Claude 세션 요약 — 2026-02-22 gene-level-diagnostic-plan

## 세션 목적

W&B run `xru1my9e`의 gene-level correlation 분석을 완료하고,
극단적 저성능(Oracle 대비 16-25%)의 원인 판별을 위한 Phase 1 진단 계획을 수립.

## 배경 컨텍스트

### 프로젝트 현황

P001_scDiffuser는 scRNA-seq 데이터 생성을 위한 diffusion transformer 모델.
ZINB decoder를 사용하며, Stage 1 (VAE 재구성) + Stage 2 (diffusion 생성) 구조.

### 이전 결론 / 선행 작업

PRB-002 (Spearman Gap) Phase 0에서 cell-level은 이미 해결:
- GT≥4 구간에서 Oracle 0.535 대비 모델 0.599 (112% 달성)
- 그러나 gene-level이 Oracle의 16-25%로 심각하게 낮음 → 새 문제 발견

## 관련 파일 위치

| 파일 | 경로 | 설명 |
|------|------|------|
| PRB-002 overview | `P001_scDiffuser/docs/problems/PRB-002_spearman_gap/_overview.md` | Phase 1 계획 |
| Oracle 코드 | `P001_scDiffuser/dev-code/scripts/oracle_bound.py` | Gene-level Oracle |
| Metric 코드 | `P001_scDiffuser/dev-code/src/scdiffuser/metrics.py` | Gene-level 모델 계산 |
| W&B run | `yunhak/scdiffuser_1/xru1my9e` | 1a 모델 |

## 주요 작업 내용
...

## 핵심 논의 / 결정사항
1. **Gene-level 저성능은 측정 버그가 아님** — 코드 검증 완료
2. **Phase 1은 "진짜 문제인가" 판별 우선** — 해결책 전에 진단
...

## 생성/수정된 산출물

| 파일 | 변경 내용 |
|------|----------|
| `PRB-002_spearman_gap/_overview.md` | Phase 1 섹션 신설 |

## 미해결 / 후속 작업

### 즉시 실행 가능 (Phase 1 Step 1-2)
**oracle_bound.py 확장 — gene sparsity bin별 Oracle 분석**:
1. gene별 nonzero fraction 계산
2. Bin (<10%, 10-30%, 30-50%, 50%+)별 Oracle 계산
3. 실행: `python oracle_bound.py --gene-sparsity-analysis`

### 조건부 (Step 2 결과에 따라)
- Dense gene에서 Oracle 초과 → WRT-001에 defense 추가
- Dense gene에서도 낮음 → Sinkhorn OT loss 검토

## 관련 문서
- 📎 Related: [[PRB-002_spearman_gap/_overview]] — Phase 1 계획
- 📎 Related: [[WRT-001_spearman_gap_defense]] — cell-level defense
```