# Adams Subroutine Writer

A [GitHub Copilot skill](https://docs.github.com/en/copilot/customizing-copilot/copilot-extensions/skills) for writing, explaining, and debugging MSC Adams/Solver user subroutines in C, C++, and Fortran.

## Why?

Adams user subroutines have complex SDK signatures, undocumented struct layouts, and
subtle rules (e.g. `iflag` guard patterns, forbidden CBKSUB calls, event constants that
change between releases). Without domain-specific guidance, AI assistants produce code
that looks plausible but won't compile — or worse, compiles but silently corrupts the
simulation.

This skill gives your AI assistant the complete Adams Solver SDK reference so it
generates correct, compilable subroutines on the first try.

## What's covered

| Subroutine | Purpose |
|------------|---------|
| **CBKSUB** | Solver lifecycle callbacks |
| **VFOSUB** | Vector force (3-component) |
| **GFOSUB** | General force (6-DOF) |
| **SFOSUB** | Scalar force (SFORCE) |
| **DIFSUB** | Differential state variable |
| **VARSUB** | VARIABLE element |
| **REQSUB** | REQUEST output |
| **COUSUB** | Coupler constraint |
| **CNFSUB** | Contact normal force |
| **CFFSUB** | Contact friction force |
| **MOTSUB** | Prescribed motion |
| **CURSUB** | Parametric curve |
| **SENSUB** / **SEVSUB** | Sensor evaluation & events |
| **FIESUB** | Field force element |
| **DMPSUB** | Flex body damping ratio |
| **GSE** | General state equations (deriv, output, update, samp) |
| **SPLINE** | Spline data reader |

Plus the utility functions: `c_sysary`, `c_sysfnc`, `c_errmes`, `c_rcnvrt`, `c_syspar`,
and the `mdi.bat` build toolchain.

## Installation

### Prerequisites

- [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) extension for VS Code (also works with Claude Code, Cursor, and Windsurf)

### Install from release

From your **project directory** (not your home directory), run:

**PowerShell:**
```powershell
mkdir -Force .agents\skills
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest "https://github.com/bthornton191/adams_skills/releases/latest/download/adams-subroutine-writer.zip" -OutFile "$env:TEMP\adams-subroutine-writer.zip"
Expand-Archive "$env:TEMP\adams-subroutine-writer.zip" -DestinationPath .agents\skills -Force
```

**Bash:**
```bash
mkdir -p .agents/skills
curl -L "https://github.com/bthornton191/adams_skills/releases/latest/download/adams-subroutine-writer.zip" -o /tmp/adams-subroutine-writer.zip
unzip -o /tmp/adams-subroutine-writer.zip -d .agents/skills
```

After installation you should have:
```
your-project/
  .agents/
    skills/
      adams-subroutine-writer/
        SKILL.md
        references/
        assets/
        scripts/
```

### Install manually

Clone this repo, then copy the skill folder into your project:

```powershell
Copy-Item -Recurse skills\adams-subroutine-writer your-project\.agents\skills\adams-subroutine-writer
```

## Usage

Once installed, the skill activates automatically when you ask your AI assistant about
Adams subroutines. Just ask naturally:

> "Write a VFOSUB that applies a spring-damper force between markers 1001 and 1002"

> "Add a CBKSUB that logs the simulation time at each output step"

> "What's wrong with my GFOSUB? It crashes during Jacobian evaluation"

The assistant will use the correct SDK signatures, symbolic constants, `iflag` guard
patterns, and build commands.

## Building subroutines

The skill instructs the assistant to compile using the Adams `mdi.bat` toolchain. On
first use it will run a setup script to locate your Adams installation:

```cmd
python .agents/skills/adams-subroutine-writer/scripts/generate_adams_env.py
```

This creates `%LOCALAPPDATA%\adams_env_init.bat`, which initializes the Adams compiler
environment. After that, the build is:

```cmd
call "%LOCALAPPDATA%\adams_env_init.bat"
mdi.bat cr-u n my_sub.c -n my_sub.dll ex
```

## Evaluation results

Tested across 28 prompts covering all subroutine types, edge cases, and common mistakes:

| | Pass rate |
|---|---|
| **With skill** | 28/28 — **100%** |
| Without skill | 2/28 — 7% |

## License

MIT
