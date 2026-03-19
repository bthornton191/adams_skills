# Adams Skills

A collection of [GitHub Copilot skills](https://docs.github.com/en/copilot/customizing-copilot/copilot-extensions/skills) for MSC Adams multibody dynamics software.

## Skills

| Skill | Description | Install |
|-------|-------------|---------|
| [adams-subroutine-writer](skills/adams-subroutine-writer/) | Write, explain, and debug Adams/Solver user subroutines in C, C++, and Fortran | [latest release](https://github.com/bthornton191/adams_skills/releases/latest/download/adams-subroutine-writer.zip) |
| [adams-cmd-model-builder](skills/adams-cmd-model-builder/) | Build, modify, and debug MSC Adams multibody models using Adams View CMD scripting | [latest release](https://github.com/bthornton191/adams_skills/releases/latest/download/adams-cmd-model-builder.zip) |
| [adams-python-model-builder](skills/adams-python-model-builder/) | Build, simulate, and post-process MSC Adams multibody models using the Adams Python API | [latest release](https://github.com/bthornton191/adams_skills/releases/latest/download/adams-python-model-builder.zip) |

## Install

Open a **PowerShell** terminal in your project directory and run:

```powershell
irm https://raw.githubusercontent.com/bthornton191/adams_skills/main/install.ps1 | iex
```

This installs all available skills into your project's skills folder. Run the same command at any time to update to the latest version.

<details>
<summary>Linux / macOS</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/bthornton191/adams_skills/main/install.sh | bash
```

</details>

<details>
<summary>Manual install</summary>

1. Go to the [latest release](https://github.com/bthornton191/adams_skills/releases/latest)
2. Download the `.zip` for the skill(s) you want
3. Extract into `.agents/skills/` in your project directory

</details>

Compatible with GitHub Copilot (VS Code), Claude Code, Cursor, and Windsurf.

## License

[MIT](LICENSE)
