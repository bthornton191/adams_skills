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

## Making a release

Create and push a `v*.*.*` tag. The `release.yml` workflow will:

1. Stamp the version from the tag into each `SKILL.md` frontmatter
2. Package all skills into `dist/*.zip`
3. Publish a GitHub Release with the zip files attached

```powershell
git tag v1.2.3
git push origin v1.2.3
```

## Key conventions

- `compatibility` in SKILL.md frontmatter must be a **comma-separated string**, not a YAML list
- SDK header files in `references/sdk_headers/` are the source of truth for function signatures and enum values

## Skill-creator JSON schemas

When creating `grading.json` or `benchmark.json` files, always read `.agents/skills/skill-creator/references/schemas.md` first. The eval viewer is strict about field names and structure:

- **grading.json**: Must contain a `summary` object (`passed`, `failed`, `total`, `pass_rate`) **and** an `expectations` array (each entry: `text`, `passed`, `evidence`). Do not use `scores` dicts, `name`/`met`/`details`, or other variants.
- **benchmark.json**: Each run must use `configuration` (not `config`), nest metrics inside a `result` object, and include an `expectations` array for the per-assertion breakdown to appear in the Benchmark tab.
- The `aggregate_benchmark.py` script expects `eval-*` directories with `run-*` subdirs. If the workspace uses a flat layout (e.g. `eval-name/with_skill/outputs/`), the script produces empty output — write `benchmark.json` manually following the schema.
- Example `.c` files in `assets/c_subroutines/examples/` are from the Adams 2023.1 installation
