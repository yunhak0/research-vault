---
guide_for: skill_creation
version: 1.0
last_updated: 2026-02-25
---

# Skill 생성 가이드

## 1. 목적

반복적으로 수행하는 작업을 **재사용 가능한 패턴**으로 문서화하여:
- Claude가 동일 작업을 일관된 품질로 수행하도록 보장
- 매번 절차를 설명하거나 교정하는 비용 제거
- `tasks/lessons.md`에 쌓인 구현 교훈을 구조화된 지식으로 승격

## 2. Skill이란

Skill은 **특정 작업에 대한 Claude의 동작 패턴을 정의하는 문서**다.

```
.vault/skills/{skill-name}/
├── SKILL.md          ← 핵심: 트리거, 절차, 입출력 사양
└── references/       ← (선택) 상세 가이드, 디자인 사양, 예시 등
```

### Skill vs 모드 vs Hook vs Lesson

| | Skill | Mode | Hook | Lesson |
|---|---|---|---|---|
| **성격** | 작업 절차서 | 응답 관점 | 자동 이벤트 | 개별 교훈 |
| **호출** | 키워드/명시적 | 컨텍스트 추론 | 이벤트 트리거 | 참조용 |
| **범위** | 특정 작업 패턴 | 전체 응답 톤 | 세션 생명주기 | 단건 실수/발견 |
| **예시** | 발표 슬라이드 생성 | AI Expert | 세션 저장 | "ruff 실행 전 venv 활성화 필요" |
| **위치** | `.vault/skills/` | `CLAUDE.md` | `.claude/hooks.json` | `tasks/lessons.md` |

**핵심 구분**: Lesson은 "이런 실수를 했다"이고, Skill은 "이 작업은 이렇게 한다"이다.

## 3. Skill 생성 시점

### 3-Strike Rule

`tasks/lessons.md`에 **동일 패턴의 교훈이 3회 이상** 누적되면 skill 후보다.

```
tasks/lessons.md:
  2026-02-10: W&B에 metric 로깅 시 step 누락 → 학습 곡선 끊김
  2026-02-15: wandb.log()에 commit=False 빠뜨림 → 중복 step
  2026-02-20: W&B run resume 안 해서 새 run 생성됨
  ← 3회 반복: "pytorch-training" skill 후보
```

### 판단 기준

| 만들어야 할 때 | 아직 이를 때 |
|---|---|
| 같은 교훈이 3회+ 반복 | 1~2회 발생 (아직 패턴 아님) |
| 절차가 5단계 이상으로 복잡 | 단순한 한 줄 규칙 |
| 실수하면 시간 낭비가 큰 작업 | 실수해도 금방 고치는 작업 |
| 여러 프로젝트에서 재사용 가능 | 특정 프로젝트에만 해당 |

### 만들지 말아야 할 것

- **단순한 코딩 규칙** → `CLAUDE.md`에 한 줄 추가로 충분
- **프로젝트 특수 설정** → 프로젝트 `CLAUDE.md`에 기록
- **일회성 워크플로우** → 세션 문서로 충분

## 4. SKILL.md 작성법

### 필수 구조

```markdown
---
name: skill-name-in-kebab-case
description: "한국어 설명. 이 skill이 무엇을 하는지, 언제 트리거되는지.
  사용자가 어떤 키워드를 말하면 활성화되는지 포함."
---

# Skill 제목

한 문장으로 이 skill의 목적.

## 사전 준비

이 skill 실행 전 읽어야 할 파일이나 확인 사항.

## 트리거 조건

이 skill이 활성화되는 상황 목록.
- 사용자가 "..." 라고 말했을 때
- 특정 파일을 편집하려 할 때
- 특정 폴더에서 작업할 때

## 절차

### Phase 1 — 이름
구체적 단계.

### Phase 2 — 이름
구체적 단계.

(...)

## 주의사항

흔한 실수와 회피 방법 (lessons.md에서 추출).

## 입출력 사양

| 항목 | 필수 | 설명 |
|------|:----:|------|
| ... | ✅/⬜ | ... |
```

### Frontmatter 규칙

| 필드 | 필수 | 설명 |
|------|:----:|------|
| `name` | ✅ | kebab-case 영어. 폴더명과 일치 |
| `description` | ✅ | Claude가 이 skill을 선택할지 판단하는 근거. 트리거 키워드 포함 |

`description`이 가장 중요하다. Claude는 이 필드를 보고 skill 활성화 여부를 판단한다. **트리거 키워드를 반드시 포함**할 것.

### 좋은 description vs 나쁜 description

```yaml
# ❌ 나쁜 예: 트리거 불명확
description: "학습 관련 패턴을 정의한 스킬"

# ✅ 좋은 예: 트리거 키워드 + 상황 명시
description: "PyTorch Lightning 학습 코드 작성·수정 시 활성화.
  W&B 로깅, GPU 메모리 관리, checkpoint 패턴 포함.
  사용자가 '학습 코드', 'training', 'W&B 로깅', 'GPU OOM' 등을 언급하면 사용."
```

## 5. references/ 폴더 활용

SKILL.md가 길어지면 (200줄+) 세부 내용을 `references/`로 분리한다.

```
.vault/skills/research-update-pptx/
├── SKILL.md              ← 전체 흐름 (워크플로우 개요, 입출력, Phase 설명)
└── references/
    ├── design-guide.md   ← 상세 디자인 사양 (색상, 폰트, 레이아웃)
    └── workflow.md        ← 각 Phase 상세 절차, 슬라이드 타입별 가이드
```

**분리 기준**:
- SKILL.md → "무엇을, 언제, 왜" (30초 만에 이해 가능)
- references/ → "어떻게" 의 상세 (실행 시 참조)

SKILL.md에서 references를 참조할 때:
```markdown
## Phase 4 — .pptx 생성
**반드시 `references/design-guide.md`의 디자인 사양을 따른다.**
```

## 6. Lesson → Skill 추출 워크플로우

```
1. tasks/lessons.md에서 반복 패턴 식별
   "W&B 로깅 관련 실수가 3건이네"

2. 패턴을 일반화
   개별 실수들 → "학습 코드 작성 시 지켜야 할 규칙 목록"

3. SKILL.md 초안 작성
   lessons의 "상황/실수/교훈" → skill의 "트리거/절차/주의사항"

4. 사용자 리뷰 → 배치
   .vault/skills/{name}/ 에 저장

5. README.md Skills 섹션에 등록

6. 사용하면서 개선
   새 교훈 발생 시 → skill 주의사항에 추가
```

### 변환 예시

**lessons.md 원본** (3건):
```markdown
## 2026-02-10: W&B step 누락
- 상황: 학습 루프에서 wandb.log() 호출
- 실수: step 인자 없이 호출 → 자동 step이 꼬임
- 교훈: 항상 wandb.log(metrics, step=global_step) 명시

## 2026-02-15: W&B commit 중복
- 상황: 여러 metric을 순차 로깅
- 실수: 매번 commit=True → step마다 여러 데이터 포인트
- 교훈: 마지막 log만 commit=True, 나머지는 commit=False

## 2026-02-20: W&B run resume 실패
- 상황: 중단된 학습 재개
- 실수: wandb.init()에 resume="allow" 누락
- 교훈: checkpoint에서 재개 시 반드시 resume="allow" + id=run_id
```

**추출된 skill** (pytorch-training/SKILL.md 일부):
```markdown
## 주의사항

### W&B 로깅
- `wandb.log(metrics, step=global_step)` — step 항상 명시
- 여러 metric 순차 로깅 시 마지막만 `commit=True`
- 학습 재개 시 `wandb.init(resume="allow", id=run_id)` 필수
```

## 7. 후보 Skill 목록

현재 사용 패턴에서 예상되는 skill 후보. `tasks/lessons.md`에 교훈이 쌓이면 생성한다.

| Skill 이름 | 역할 | 트리거 키워드 |
|------------|------|--------------|
| `pytorch-training` | Lightning 학습 패턴, W&B 로깅, GPU 메모리 관리, checkpoint | "학습 코드", "training", "W&B", "GPU OOM", "checkpoint" |
| `hpc-job` | SLURM/neuron 작업 제출, 모니터링, 디버깅 | "서버 작업", "SLURM", "sbatch", "neuron", "GPU 할당" |
| `analysis-notebook` | analyze/ 폴더 분석 스크립트 패턴, 재현성 규칙 | "분석 스크립트", "analyze/", "그래프", "figure" |

> 이 목록은 참고용이다. 실제 생성은 교훈 누적 후 판단한다.

## 8. 환경별 Skill 배치

| 환경 | Skill 위치 | 읽는 주체 |
|------|-----------|----------|
| **claude.ai** (이 vault) | `.vault/skills/` | 사용자가 "발표 자료 만들어줘" → Claude가 SKILL.md 참조 |
| **Claude Code** (프로젝트 repo) | `skills/` (프로젝트 루트) | Claude Code가 자동 인식 또는 `CLAUDE.md`에서 참조 |

claude.ai에서는 사용자의 요청 + `CLAUDE.md`에서의 안내를 통해 skill을 활용한다.
Claude Code에서는 프로젝트 루트의 `skills/` 폴더를 자동으로 인식할 수 있다.

동일 skill을 양쪽에서 사용하려면:
- `.vault/skills/`에 원본 유지 (claude.ai용)
- 프로젝트 `skills/`에 심볼릭 링크 또는 복사 (Claude Code용)
