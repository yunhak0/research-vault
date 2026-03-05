# macOS 환경 설치 가이드

이 문서는 macOS에서 Research Vault를 사용하기 위해 필요한 도구들을 설치하는 과정을 안내합니다.

## 목차

1. [사전 준비](#1-사전-준비)
2. [Homebrew 설치](#2-homebrew-설치)
3. [기본 도구 설치](#3-기본-도구-설치)
4. [uv 설치](#4-uv-설치)
5. [nvm + Node.js 설치](#5-nvm--nodejs-설치)
6. [Claude Desktop 설치](#6-claude-desktop-설치)
7. [Claude Desktop — Connector 설정](#7-claude-desktop--connector-설정)
8. [Claude Desktop — 프로젝트 설정](#8-claude-desktop--프로젝트-설정)
9. [Claude Desktop — Developer MCP 서버 설정](#9-claude-desktop--developer-mcp-서버-설정)
10. [Claude Code — MCP 서버 설정](#10-claude-code--mcp-서버-설정)
11. [Research Vault 설치](#11-research-vault-설치)
12. [설치 확인 체크리스트](#12-설치-확인-체크리스트)

---

## 1. 사전 준비

도구 설치 전에 필요한 외부 서비스 가입과 앱 설치를 먼저 진행합니다.

### Obsidian 설치 및 Local REST API 플러그인 활성화

**Obsidian**은 로컬 마크다운 파일 기반의 노트 앱입니다. Research Vault의 모든 문서를 Obsidian에서 열람하고 관리합니다.

**1) Obsidian을 다운로드합니다.**

- [obsidian.md/download](https://obsidian.md/download)에서 macOS용 `.dmg` 파일을 다운로드합니다.

**2) 설치합니다.**

다운로드한 `.dmg` 파일을 열고, Obsidian 아이콘을 Applications 폴더로 드래그합니다.

**3) Local REST API 플러그인을 설치합니다.**

이 플러그인은 Claude Desktop이 Obsidian vault에 접근할 수 있게 해줍니다.

1. Obsidian 실행
2. 설정 (왼쪽 하단 톱니바퀴) → **커뮤니티 플러그인** → **커뮤니티 플러그인 탐색**
3. "Local REST API" 검색 → **설치** → **활성화**
4. 플러그인 설정에서 **API Key**를 확인하고 복사해 둡니다

> 이 API Key는 나중에 MCP 서버 설정([9단계](#9-claude-desktop--developer-mcp-서버-설정))에서 사용합니다.

### W&B (Weights & Biases) API 키 발급 — 선택

ML 실험 추적을 사용할 경우 W&B API 키를 미리 발급받아 환경 변수에 저장해 둡니다.

**1) 계정을 생성합니다.**

- [wandb.ai](https://wandb.ai)에서 가입합니다.

**2) API 키를 발급합니다.**

- 로그인 후 [wandb.ai/authorize](https://wandb.ai/authorize) 또는 Settings → API Keys에서 키를 복사합니다.

**3) 환경 변수에 저장합니다.**

```bash
echo 'export WANDB_API_KEY="여기에_API_키_붙여넣기"' >> ~/.zshrc
source ~/.zshrc
```

**4) 저장을 확인합니다.**

```bash
echo $WANDB_API_KEY
```

키가 출력되면 성공입니다.

---

## 2. Homebrew 설치

**Homebrew**는 macOS용 패키지 관리자입니다. 터미널에서 명령어 하나로 다양한 도구를 설치할 수 있게 해줍니다.

**1) 터미널을 엽니다.**

- Spotlight (Cmd + Space) → "Terminal" 검색하여 실행

**2) Homebrew를 설치합니다.**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

설치 과정에서 macOS 비밀번호를 입력해야 할 수 있습니다.

**3) (Apple Silicon Mac만 해당) PATH를 설정합니다.**

M1/M2/M3/M4 Mac을 사용하는 경우, 설치 완료 후 출력되는 안내에 따라 PATH를 추가합니다:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**4) 설치를 확인합니다.**

```bash
brew --version
```

버전 번호가 출력되면 성공입니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `brew: command not found` (Apple Silicon) | 위 3번의 PATH 설정을 확인. 터미널을 닫고 새로 열기 |
| Xcode 관련 오류 | `xcode-select --install` 실행 후 재시도 |

---

## 3. 기본 도구 설치

```bash
brew install git jq
```

각 도구의 역할:

| 도구 | 용도 |
|------|------|
| `git` | 소스 코드 버전 관리 |
| `jq` | JSON 데이터 처리 (Claude Code hooks에 필요) |

> `curl`은 macOS에 기본 포함되어 있으므로 별도 설치가 불필요합니다.

설치를 확인합니다.

```bash
git --version
jq --version
```

---

## 4. uv 설치

**uv**는 Python 패키지 관리 도구입니다. 기존의 pip, venv, virtualenv를 대체하며, 훨씬 빠른 속도로 패키지를 설치합니다.

**1) 설치 스크립트를 실행합니다.**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.zshrc
```

> macOS는 기본 셸이 zsh입니다.

**3) 설치를 확인합니다.**

```bash
uv --version
```

버전 번호가 출력되면 성공입니다 (예: `uv 0.6.x`).

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `uv: command not found` | `source ~/.zshrc` 실행 후 재시도. 안 되면 터미널을 닫고 새로 열기 |

---

## 5. nvm + Node.js 설치

**nvm(Node Version Manager)**은 Node.js의 여러 버전을 설치하고 전환할 수 있는 도구입니다. Claude Code와 일부 MCP 서버 실행에 Node.js가 필요합니다.

**1) nvm을 설치합니다.**

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.zshrc
```

> `~/.zshrc` 파일이 없다는 오류가 나오면 먼저 `touch ~/.zshrc`로 생성한 후, 1번 설치를 다시 실행합니다.

**3) nvm 설치를 확인합니다.**

```bash
command -v nvm
```

`nvm`이 출력되면 성공입니다.

> `which nvm`은 동작하지 않습니다. nvm은 실행 파일이 아닌 셸 함수이기 때문입니다.

**4) Node.js LTS 버전을 설치합니다.**

```bash
nvm install --lts
```

**5) 설치를 확인합니다.**

```bash
node --version
npx --version
```

버전 번호가 출력되면 성공입니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `nvm: command not found` | 터미널을 닫고 새로 열기 |
| `node: command not found` | `nvm use --lts` 실행 |

---

## 6. Claude Desktop 설치

**1) Claude Desktop을 다운로드합니다.**

- [claude.ai/download](https://claude.ai/download)에서 macOS용 `.dmg` 파일을 다운로드합니다.

**2) 설치합니다.**

다운로드한 `.dmg` 파일을 열고, Claude 아이콘을 Applications 폴더로 드래그합니다.

**3) 로그인합니다.**

Claude 앱을 실행하고 계정으로 로그인합니다. 유료 구독(Pro/Team/Enterprise)이 필요합니다.

---

## 7. Claude Desktop — Connector 설정

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

## 8. Claude Desktop — 프로젝트 설정

Claude Desktop의 **Project** 기능을 사용하면 대화마다 자동으로 적용되는 지시문(instruction)을 설정할 수 있습니다. Research Vault 전용 프로젝트를 만들어 연구 어시스턴트 규칙을 등록합니다.

### 프로젝트 생성

1. Claude Desktop 앱 열기
2. 좌측 사이드바에서 **Projects** 클릭
3. **Create Project** 클릭
4. 프로젝트 이름 입력 (예: `Research Vault`)

### Instruction 추가

1. 생성한 프로젝트 페이지에서 **Set custom instructions** 클릭
2. Research Vault 저장소의 `docs/claude_desktop_project_instruction_example.md` 내용을 복사하여 붙여넣기
3. **경로를 본인의 vault 경로로 수정합니다:**

수정이 필요한 부분:

```
# 수정 전 (예시)
→ Filesystem:read_text_file path=/Users/yunhakoh/Documents/vault/CLAUDE.md
base path: /Users/yunhakoh/Documents/vault

# 수정 후 (본인 경로로 변경)
→ Filesystem:read_text_file path=/Users/본인계정/Documents/vault/CLAUDE.md
base path: /Users/본인계정/Documents/vault
```

> 경로는 `setup.sh install`에서 지정한 vault 경로와 동일해야 합니다.

4. **Save** 클릭

### 사용 방법

프로젝트 내에서 새 대화를 시작하면 설정한 instruction이 자동으로 적용됩니다. 프로젝트 페이지에서 **Start new chat**을 클릭하거나, 새 대화 시작 시 해당 프로젝트를 선택합니다.

---

## 9. Claude Desktop — Developer MCP 서버 설정

**Developer MCP 서버**는 설정 파일(`claude_desktop_config.json`)을 직접 편집하여 연결하는 외부 서버입니다. Connector로 제공되지 않는 기능을 추가할 때 사용합니다.

### 설정 파일 위치

```
~/Library/Application Support/Claude/claude_desktop_config.json
```

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

**사전 요구사항**: Obsidian의 Local REST API 플러그인이 설치·활성화되어 있어야 합니다 ([1단계](#1-사전-준비) 참조).

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

`uvx`를 못 찾는 경우, 전체 경로를 사용합니다:

```json
"command": "/Users/username/.local/bin/uvx"
```

경로 확인: `which uvx`

### W&B (실험 추적 — 선택)

W&B(Weights & Biases)로 ML 실험 결과를 조회할 수 있게 합니다.

**사전 요구사항**: W&B API 키가 환경 변수에 설정되어 있어야 합니다 ([1단계](#1-사전-준비) 참조).

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

> `~/.zshrc`에 `WANDB_API_KEY`를 설정한 경우에도, Claude Desktop은 셸 환경 변수를 상속하지 않으므로 위 설정에 키를 직접 입력해야 합니다.

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

## 10. Claude Code — MCP 서버 설정

Claude Code에서 사용할 MCP 서버는 `claude mcp add` 명령어로 등록합니다.

> 아래 서버들은 Research Vault의 `setup.sh` 스크립트로도 자동 설정할 수 있습니다 ([11단계](#11-research-vault-설치) 참조).

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

## 11. Research Vault 설치

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
source ~/.zshrc
```

### Obsidian에서 Vault 열기

1. Obsidian 실행
2. **Open folder as vault** 선택
3. `setup.sh install`에서 지정한 vault 경로를 선택

---

## 12. 설치 확인 체크리스트

모든 설치가 완료되었는지 아래 항목을 확인합니다.

### 기본 도구

- [ ] `uv --version` — 버전 출력 확인
- [ ] `node --version` — 버전 출력 확인
- [ ] `npx --version` — 버전 출력 확인

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

모든 항목이 체크되었다면 Research Vault 사용 준비가 완료된 것입니다.
