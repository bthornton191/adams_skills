# Adams Skills

A collection of [GitHub Copilot skills](https://docs.github.com/en/copilot/customizing-copilot/copilot-extensions/skills) for MSC Adams multibody dynamics software.

## Skills

| Skill | Description | Install |
|-------|-------------|---------|
| [adams-subroutine-writer](skills/adams-subroutine-writer/) | Write, explain, and debug Adams/Solver user subroutines in C, C++, and Fortran | [latest release](https://github.com/bthornton191/adams_skills/releases/latest/download/adams-subroutine-writer.zip) |

## Quick install

From your **project directory**, download and extract the skill you want:

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

Compatible with GitHub Copilot (VS Code), Claude Code, Cursor, and Windsurf.

## License

[MIT](LICENSE)
