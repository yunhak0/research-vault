# Windows 환경 설치 가이드

이 문서는 Windows에서 Research Vault를 사용하기 위해 필요한 도구들을 설치하는 과정을 안내합니다.

> **중요**: Windows에서는 **WSL(Windows Subsystem for Linux)**을 통해 리눅스 환경에서 작업합니다.
> Research Vault가 symlink을 사용하기 때문에 Git Bash나 PowerShell에서는 정상 동작하지 않습니다.

## 목차

1. [WSL 설치](#1-wsl-설치)
2. [기본 도구 설치](#2-기본-도구-설치)
3. [uv 설치](#3-uv-설치)
4. [nvm + Node.js 설치](#4-nvm--nodejs-설치)
5. [Claude Desktop 설치](#5-claude-desktop-설치)
6. [Claude Code 설치](#6-claude-code-설치)
7. [다음 단계](#다음-단계)

---

## 1. WSL 설치

**WSL(Windows Subsystem for Linux)**은 Windows 안에서 리눅스를 실행할 수 있게 해주는 기능입니다. 별도의 가상 머신 없이 리눅스 명령어와 도구를 바로 사용할 수 있습니다.

### 요구사항

- Windows 10 버전 2004 (Build 19041) 이상 또는 Windows 11
- 관리자 권한

### 설치 절차

**1) PowerShell을 관리자 권한으로 실행합니다.**

- 시작 메뉴에서 "PowerShell" 검색
- "관리자 권한으로 실행" 클릭

**2) WSL 설치 명령을 실행합니다.**

```powershell
wsl --install
```

이 명령은 WSL과 함께 Ubuntu를 기본 배포판으로 설치합니다.

**3) 컴퓨터를 재시작합니다.**

설치 완료 후 재부팅이 필요합니다.

**4) Ubuntu 초기 설정을 진행합니다.**

재부팅 후 Ubuntu가 자동으로 실행되며, 사용자 이름과 비밀번호를 설정합니다.

```
Enter new UNIX username: myname
New password: ********
Retype new password: ********
```

> 비밀번호는 입력해도 화면에 표시되지 않습니다. 그냥 입력하고 Enter를 누르세요.

**5) 설치를 확인합니다.** (PowerShell에서)

```powershell
wsl --list --verbose
```

Ubuntu가 VERSION 2로 표시되면 정상입니다.

### Windows Terminal 설치 (권장)

Microsoft Store에서 "Windows Terminal"을 설치하면 WSL 터미널을 더 편리하게 사용할 수 있습니다. 탭 기능, 글꼴 설정 등을 지원합니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| 설치가 0.0%에서 멈춤 | `wsl --install --web-download -d Ubuntu` 시도 |
| "가상화 기능이 비활성화" 오류 | BIOS에서 가상화(VT-x/AMD-V) 활성화 필요 |
| WSL 1으로 설치됨 | `wsl --set-version Ubuntu 2`로 업그레이드 |

---

## 2. 기본 도구 설치

이후 모든 작업은 **WSL(Ubuntu) 터미널** 안에서 진행합니다.

WSL 터미널 진입 방법:
- Windows Terminal에서 Ubuntu 탭 선택, 또는
- 시작 메뉴에서 "Ubuntu" 검색하여 실행

**1) 패키지 목록을 업데이트합니다.**

```bash
sudo apt update && sudo apt upgrade -y
```

**2) 필수 도구를 설치합니다.**

```bash
sudo apt install -y git curl jq build-essential
```

각 도구의 역할:

| 도구 | 용도 |
|------|------|
| `git` | 소스 코드 버전 관리 |
| `curl` | URL에서 파일 다운로드 |
| `jq` | JSON 데이터 처리 (Claude Code hooks에 필요) |
| `build-essential` | C/C++ 컴파일러 (일부 패키지 빌드에 필요) |

**3) 설치를 확인합니다.**

```bash
git --version
curl --version
jq --version
```

---

## 3. uv 설치

**uv**는 Python 패키지 관리 도구입니다. 기존의 pip, venv, virtualenv를 대체하며, 훨씬 빠른 속도로 패키지를 설치합니다.

**1) 설치 스크립트를 실행합니다.** (WSL 터미널에서)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.bashrc
```

> zsh를 사용하는 경우 `source ~/.zshrc`

**3) 설치를 확인합니다.**

```bash
uv --version
```

버전 번호가 출력되면 성공입니다 (예: `uv 0.6.x`).

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `uv: command not found` | `source ~/.bashrc` 실행 후 재시도. 안 되면 새 터미널 열기 |
| curl 오류 | `sudo apt install curl` 후 재시도 |

---

## 4. nvm + Node.js 설치

**nvm(Node Version Manager)**은 Node.js의 여러 버전을 설치하고 전환할 수 있는 도구입니다. Claude Code와 일부 MCP 서버 실행에 Node.js가 필요합니다.

**1) nvm을 설치합니다.** (WSL 터미널에서)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
```

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.bashrc
```

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

## 5. Claude Desktop 설치

Claude Desktop은 **Windows 앱**으로 설치합니다 (WSL이 아님).

**1) Claude Desktop을 다운로드합니다.**

- [claude.ai/download](https://claude.ai/download)에서 Windows용 설치 파일을 다운로드합니다.

**2) 설치 파일을 실행합니다.**

다운로드한 `.exe` 파일을 실행하여 설치를 진행합니다.

**3) 로그인합니다.**

Claude 계정으로 로그인합니다. 유료 구독(Pro/Team/Enterprise)이 필요합니다.

---

## 6. Claude Code 설치

Claude Code는 **WSL 터미널** 안에서 설치합니다.

**1) Claude Code를 설치합니다.**

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

> 이 방식으로 설치하면 자동 업데이트가 지원됩니다.

**2) 셸 설정을 다시 불러옵니다.**

```bash
source ~/.bashrc
```

**3) 설치를 확인합니다.**

```bash
claude --version
```

**4) 인증을 진행합니다.**

```bash
claude
```

처음 실행하면 브라우저에서 로그인하라는 안내가 나옵니다. 안내에 따라 인증을 완료합니다.

### 트러블슈팅

| 증상 | 해결 방법 |
|------|---------|
| `claude: command not found` | `source ~/.bashrc` 실행 후 재시도. 안 되면 새 터미널 열기 |
| 브라우저가 열리지 않음 | WSL에서 표시되는 URL을 복사하여 Windows 브라우저에 직접 붙여넣기 |

---

## 다음 단계

도구 설치가 완료되었습니다. 다음으로 MCP 서버 설정과 Research Vault 설치를 진행합니다:

→ [공통 설정 가이드 (MCP 서버 + Vault)](1_setup-common.md)
