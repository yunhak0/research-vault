# 공통 설정 가이드 (MCP 서버 + Vault)

이 문서는 OS별 도구 설치를 마친 후, Claude Desktop MCP 서버 설정과 Research Vault 설치를 안내합니다.

> **사전 요구사항**: [Windows 설치 가이드](0_setup-windows.md) 또는 [macOS 설치 가이드](0_setup-macos.md)를 먼저 완료하세요.

## 목차

1. [Obsidian 설치](#1-obsidian-설치)
2. [Claude Desktop — Connector 설정](#2-claude-desktop--connector-설정)
3. [Claude Desktop — Developer MCP 서버 설정](#3-claude-desktop--developer-mcp-서버-설정)
4. [Claude Code — MCP 서버 설정](#4-claude-code--mcp-서버-설정)
5. [Research Vault 설치](#5-research-vault-설치)
6. [설치 확인 체크리스트](#6-설치-확인-체크리스트)

---

## 1. Obsidian 설치

**Obsidian**은 로컬 마크다운 파일 기반의 노트 앱입니다. Research Vault의 모든 문서를 Obsidian에서 열람하고 관리합니다.

**1) Obsidian을 다운로드합니다.**

- [obsidian.md/download](https://obsidian.md/download)에서 자신의 OS에 맞는 버전을 다운로드합니다.

**2) 설치하고 실행합니다.**

**3) Local REST API 플러그인을 설치합니다.**

이 플러그인은 Claude Desktop이 Obsidian vault에 접근할 수 있게 해줍니다.

1. Obsidian 설정 (왼쪽 하단 톱니바퀴) → 커뮤니티 플러그인 → 커뮤니티 플러그인 탐색
2. "Local REST API" 검색 → 설치 → 활성화
3. 플러그인 설정에서 API Key를 확인하고 복사해 둡니다 (나중에 MCP 설정에 필요)

---

## 2. Claude Desktop — Connector 설정

**Connector**는 Claude Desktop 앱의 UI에서 직접 활성화하는 내장 연동 기능입니다. 설정 파일을 편집할 필요 없이 클릭만으로 연결됩니다.

### 설정 방법

1. Claude Desktop 앱 열기
2. 설정 (Settings) 진입
3. **Integrations** 또는 **Connectors** 메뉴에서 필요한 서비스를 활성화

### 권장 Connector

| Connector | 용도 | 설정 방법 |
|-----------|------|---------|
| **Filesystem** | 로컬 파일 읽기/쓰기 (vault 접근) | 활성화 후 접근 허용할 디렉토리 경로 추가 |
| **Notion** | 연구 결론 아카이빙 | Notion 계정 로그인으로 연결 |
| **PubMed** | 학술 논문 검색 | 활성화만 하면 사용 가능 |
| **bioRxiv** | 생물학 프리프린트 검색 | 활성화만 하면 사용 가능 |

> Filesystem connector에는 vault가 설치될 경로를 추가해야 합니다 (예: `/Users/username/Documents/vault`).

---

## 3. Claude Desktop — Developer MCP 서버 설정

**Developer MCP 서버**는 설정 파일(`claude_desktop_config.json`)을 직접 편집하여 연결하는 외부 서버입니다. Connector로 제공되지 않는 기능을 추가할 때 사용합니다.

### 설정 파일 위치

| OS | 경로 |
|----|------|
| macOS | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Windows | `%APPDATA%\Claude\claude_desktop_config.json` |

설정 파일이 없으면 새로 생성합니다.

### 설정 파일 기본 구조

```json
{
    "mcpServers": {

    }
}
```

`mcpServers` 안에 각 서버를 추가합니다. 아래의 필요한 서버를 골라서 추가하세요.

### mcp-obsidian (Vault 연동 — 권장)

Claude Desktop에서 Obsidian vault의 내용을 검색하고 수정할 수 있게 합니다.

**사전 요구사항**: Obsidian의 Local REST API 플러그인이 설치·활성화되어 있어야 합니다 ([1단계](#1-obsidian-설치) 참조).

```json
{
    "mcpServers": {
        "mcp-obsidian": {
            "command": "uvx",
            "args": ["mcp-obsidian"],
            "env": {
                "OBSIDIAN_API_KEY": "여기에_Local_REST_API_키를_붙여넣기"
            }
        }
    }
}
```

> `OBSIDIAN_API_KEY`는 Obsidian → 설정 → Local REST API 플러그인 → API Key에서 확인할 수 있습니다.

macOS에서 `uvx`를 못 찾는 경우, 전체 경로를 사용합니다:

```json
"command": "/Users/username/.local/bin/uvx"
```

경로 확인 방법: 터미널에서 `which uvx` 실행

### W&B (실험 추적 — 선택)

W&B(Weights & Biases)로 ML 실험 결과를 조회할 수 있게 합니다.

**사전 요구사항**: [wandb.ai](https://wandb.ai)에서 계정 생성 후 Settings → API Keys에서 키를 발급합니다.

```json
{
    "mcpServers": {
        "wandb": {
            "command": "uvx",
            "args": [
                "--from", "git+https://github.com/wandb/wandb-mcp-server",
                "wandb_mcp_server"
            ],
            "env": {
                "WANDB_API_KEY": "여기에_W&B_API_키를_붙여넣기"
            }
        }
    }
}
```

### Context7 (라이브러리 문서 조회 — 선택)

최신 라이브러리 문서를 Claude에서 바로 검색할 수 있게 합니다.

```json
{
    "mcpServers": {
        "context7": {
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp"]
        }
    }
}
```

### 여러 서버를 함께 설정하는 예시

```json
{
    "mcpServers": {
        "mcp-obsidian": {
            "command": "uvx",
            "args": ["mcp-obsidian"],
            "env": {
                "OBSIDIAN_API_KEY": "your-api-key"
            }
        },
        "context7": {
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp"]
        }
    }
}
```

> 설정 파일 수정 후 **Claude Desktop을 재시작**해야 적용됩니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| MCP 서버가 연결되지 않음 | Claude Desktop을 완전히 종료 후 재시작 |
| uvx 또는 npx를 찾을 수 없음 | command에 전체 경로 사용 (예: `/Users/username/.local/bin/uvx`) |
| JSON 문법 오류 | 쉼표, 중괄호, 따옴표가 올바른지 확인 |
| Obsidian 연결 실패 | Obsidian이 실행 중이고, Local REST API 플러그인이 활성화되어 있는지 확인 |

---

## 4. Claude Code — MCP 서버 설정

Claude Code에서 사용할 MCP 서버는 `claude mcp add` 명령어로 등록합니다.

> 아래 서버들은 Research Vault의 `setup.sh` 스크립트로도 자동 설정할 수 있습니다 ([5단계](#5-research-vault-설치) 참조).

### Notion (연구 아카이빙)

```bash
claude mcp add notion --scope user -- npx -y @anthropic/notion-mcp-server
```

### bioRxiv (프리프린트 검색)

```bash
claude mcp add bioRxiv --scope user -- npx -y @anthropic/biorxiv-mcp-server
```

### PubMed (논문 검색)

```bash
claude mcp add PubMed --scope user -- npx -y @anthropic/pubmed-mcp-server
```

### 등록 확인

```bash
claude mcp list
```

등록된 MCP 서버 목록이 출력됩니다.

> **참고**: mcp-obsidian, W&B, Context7은 `setup.sh obsidian`, `setup.sh wandb`, `setup.sh context7` 명령으로 자동 등록됩니다. 아래 Research Vault 설치 과정에서 안내합니다.

---

## 5. Research Vault 설치

### 저장소 클론

```bash
git clone git@github.com:yunhak0/research-vault.git
cd research-vault
```

> SSH key가 설정되지 않은 경우 HTTPS를 사용합니다:
>
> ```bash
> git clone https://github.com/yunhak0/research-vault.git
> ```

### Vault 초기 설치

```bash
bash setup.sh install
```

대화형으로 다음을 설정합니다:

- Vault 설치 경로 (예: `~/Documents/vault`)
- 소유자 이름
- Notion 연동 여부

### 첫 프로젝트 생성

```bash
bash setup.sh project
```

프로젝트 ID, 이름, 코드 저장소 경로를 입력합니다.

### Daily 자동화 설치

```bash
bash setup.sh daily
```

셸에 `daily-start`, `daily-update` alias를 등록합니다. 설치 후 셸을 다시 불러옵니다:

```bash
source ~/.zshrc    # macOS
source ~/.bashrc   # WSL/Linux
```

### MCP 서버 자동 설정 (선택)

Claude Code에서 사용할 MCP 서버를 자동으로 등록합니다:

```bash
bash setup.sh obsidian   # mcp-obsidian (vault 연동)
bash setup.sh wandb      # W&B (실험 추적)
bash setup.sh context7   # Context7 (라이브러리 문서)
```

### Obsidian에서 Vault 열기

1. Obsidian 실행
2. **Open folder as vault** 선택
3. `setup.sh install`에서 지정한 vault 경로를 선택

---

## 6. 설치 확인 체크리스트

모든 설치가 완료되었는지 아래 항목을 확인합니다.

### 기본 도구

- [ ] `uv --version` — 버전 출력 확인
- [ ] `node --version` — 버전 출력 확인
- [ ] `npx --version` — 버전 출력 확인
- [ ] `claude --version` — 버전 출력 확인

### Claude Desktop

- [ ] 앱 실행 및 로그인 성공
- [ ] Connector (Filesystem, Notion 등) 활성화 확인
- [ ] Developer MCP 서버 연결 확인 (설정한 경우)

### Obsidian

- [ ] Obsidian에서 vault 열기 성공
- [ ] Local REST API 플러그인 활성화 확인

### Research Vault

- [ ] `daily-start` 명령 동작 확인
- [ ] Claude Desktop에서 vault 문서 접근 가능 확인

모든 항목이 체크되었다면 Research Vault 사용 준비가 완료된 것입니다. README.md의 사용법을 참고하여 시작하세요.
