# Development Instructions

This repo contains AI coding skills for MSC Adams. Each skill lives in `skills/<skill-name>/` and is packaged as a `.zip` file for distribution.

## Project structure

```
skills/
  <skill-name>/
    SKILL.md          # Skill definition (YAML frontmatter + markdown instructions)
    references/       # Domain knowledge files the skill reads
    assets/           # Templates, example code
    scripts/          # Helper scripts (e.g. generate_adams_env.py)
    evals/            # Test prompts and grading (dev-only, excluded from .zip package)
    README.md         # Skill-specific docs (excluded from .zip package)
.agents/
  skills/
    skill-creator/    # Tooling for creating, testing, and packaging skills
dist/                 # Build output (.zip files) — gitignored
```

## Adams terminology

- The `.adm` file is the **Adams dataset file**, not "model file"
- `AdamsSetup.bat` is the environment initialisation script (in `<install>/common/`)
- `mdi.bat` is the build tool for compiling user subroutines into DLLs
- Always use `ev_*`, `am_*`, `sn_*`, `cm_*` symbolic constants, never raw integers

## Packaging a skill

```powershell
cd .agents\skills\skill-creator
python -m scripts.package_skill ..\..\..\skills\<skill-name> ..\..\..\dist
```

This creates `dist/<skill-name>.zip` (a ZIP archive). The packager automatically excludes `evals/`, `README.md`, `__pycache__/`, and `*.pyc`.

## Running evals

```powershell
cd .agents\skills\skill-creator
python -m scripts.run_eval ..\..\..\skills\<skill-name>
```

Eval prompts are in `skills/<skill-name>/evals/evals.json`. Results and grading go in `evals/results/`.

## Key conventions

- `compatibility` in SKILL.md frontmatter must be a **comma-separated string**, not a YAML list
- SDK header files in `references/sdk_headers/` are the source of truth for function signatures and enum values
- Example `.c` files in `assets/c_subroutines/examples/` are from the Adams 2023.1 installation
