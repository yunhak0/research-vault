---
guide_for: engineering
version: 1.0
last_updated: 2026-02-16
---

# Engineering 문서 작성 가이드

## 1. 목적

프로젝트의 **코드 품질·성능·유지보수성**을 개선하는 엔지니어링 작업을 기록하는 문서.
연구 목표(왜 이런 결과가 나오는가?)와 직접 결합되지 않는, 순수 기술적 개선이 대상이다.
논문 Methods/Results에는 들어가지 않는 작업을 다룬다.

## 2. ID 규칙

```
ENG-[NNN]

예시: ENG-001

- ENG: 고정 문자열 (Engineering)
- NNN: 3자리 순번 (프로젝트 내 전역)
```

## 3. 파일 위치

```
[PROJECT]/engineering/ENG-[NNN]_[name].md

예시: P001_scDiffuser/engineering/ENG-001_data_pipeline_optimization.md
```

## 4. Engineering 대상

**대상 예시:**
- 데이터 파이프라인 성능 최적화 (throughput, GPU utilization)
- 코드 리팩토링 (모듈 분리, API 정리)
- HPC/컨테이너 환경 설정
- CI/CD, 테스트 인프라
- 빌드 시스템, 의존성 관리

**Engineering이 아닌 것:**
- 모델 아키텍처 결정 → FND
- 메트릭/평가 방법론 선택 → FND
- 연구적 발견이 포함된 문제 해결 → PRB
- 논문에 Methods로 기술될 내용 → FND 또는 PRB

**구분 기준**: "이 작업의 결과가 논문에 들어가는가?"
- Yes → FND 또는 PRB
- No → ENG

## 5. 섹션별 작성 규칙

### 5.1 목표 (Blockquote)

**형식**: `> **목표**: ...`로 시작하는 한 문장.

### 5.2 배경

**현재 문제**: 수치/로그 기반으로 현재 상태의 문제점 기술.
**영향 범위**: 어떤 파일, 어떤 환경, 어떤 워크플로우에 영향을 미치는가.

### 5.3 개선 계획

**단계별 로드맵**: Stage 구분이 있으면 각 Stage의 착수 조건과 기대 효과.
**세부 항목**: 각 변경사항의 구체적 내용.

### 5.4 구현 우선순위

테이블로 정리. 노력 대비 효과 순서로 정렬.

### 5.5 검증 방법

**성능 지표**: throughput, latency, GPU utilization 등 정량 지표.

**품질 회귀 방어**: 기능 변경이 학습 결과에 영향을 주지 않는지 확인하는 방법. 두 가지 도구를 사용한다:

#### Integrity Gates

파이프라인 주요 지점에 자동 검증을 설치하여, 무결성이 깨지면 즉시 감지하는 매커니즘.

**테이블 작성 규칙**:
- **Gate**: 검증 항목의 이름 (예: "Data shape check", "Loss NaN guard", "Gradient norm cap")
- **검증 시점**: 파이프라인의 어느 단계에서 실행되는지 (Pre-train / Mid-train / Post-train / Data loading 등)
- **통과 조건**: 정량적으로 명시 (예: "loss < 10.0", "gradient norm < 100", "output shape == (B, G)")
- **실패 시 행동**: Stop (학습 중단) / Warn (경고 로그) / Log (기록만)
- **구현 위치**: 실제 코드 위치 (예: `train.py:L45`, `data_loader.py:validate()`)

**예시**:
```
| Gate | 검증 시점 | 통과 조건 | 실패 시 행동 | 구현 위치 |
|------|----------|----------|-------------|----------|
| Loss NaN guard | Mid-train (every step) | loss 이 finite | Stop | train.py:L120 |
| Data shape check | Data loading | batch.shape == (B, G) | Stop | dataset.py:__getitem__ |
| Metric sanity | Post-train | Pearson > 0.1 | Warn | evaluate.py:validate() |
```

#### 회귀 테스트

변경 전후를 비교하여 기능이 망가지지 않았음을 확인하는 테스트.

**테이블 작성 규칙**:
- **테스트**: 회귀 항목의 이름
- **기준값 (Before)**: 변경 전 실측치
- **허용 범위**: 허용 가능한 변동 폭 (예: "±0.02", ">= 0.85")
- **측정 스크립트**: `analyze/` 내 스크립트 경로

### 5.6 진행 로그

실제 구현 과정을 날짜별로 기록.

## 6. Status 정의

| 상태 | 정의 |
|------|------|
| Draft | 계획 수립 중 |
| In Progress | 구현 진행 중 |
| Completed | 모든 항목 적용 완료, 검증 완료 |

## 7. PRB와의 관계

ENG 작업 중 연구적 발견이 나오면, 해당 발견은 PRB 또는 FND로 분리하여 기록한다.

## 8. Notion 아카이빙

- **아카이빙 대상**: `status: Completed`
- **Type**: `ENG`
- 연구 아카이브보다 우선순위 낮음. 중요한 인프라 변경만 선택적으로 아카이빙.