# Adams Python Model Builder Skill

A complete reference for building MSC Adams multibody dynamics models using the Adams Python API (`import Adams`) inside Adams View.

## What this skill covers

- **API patterns** — manager-based creation, dot-path object names, property assignment, object vs string references
- **Build workflow** — model → defaults → parts → markers → geometry → constraints → forces → simulation
- **Force type selection** — when to use TranslationalSpringDamper vs Bushing vs SingleComponentForce vs GeneralForce
- **FUNCTION= expressions** — the full run-time expression library passed as Python strings: smoothing (STEP, HAVSIN), contact (IMPACT, BISTOP), splines (AKISPL, CUBSPL), kinematics, force readback, data elements, math — identical syntax to Adams CMD
- **Design variables** — `Adams.expression()` to build solver-evaluated parametric strings linked to DVs
- **Simulation & post-processing** — `Simulations.create()`, `Analysis.results` nested dict, Measures API
- **Example scripts** — simple pendulum, parametric N-link chain, crank-slider mechanism

## Relationship to the CMD skill

The Adams Python API and Adams CMD scripting are two different interfaces to the same Adams View data model. This skill covers Python only. See [`adams-cmd-model-builder`](../adams-cmd-model-builder/) for the CMD interface.

Key differences:
| Topic | CMD | Python |
|-------|-----|--------|
| Model creation | `model create model_name=foo` | `Adams.models.create(name='foo')` |
| Property assignment | keyword arguments | direct attribute assignment (`part.mass = 1.0`) |
| Loops | `for/end` + `RTOI()` | plain Python `for` loop + f-strings |
| Object references | string dot-path always | Python object (preferred) or string dot-path |
| Expressions | `FUNCTION=` keyword | string passed to `.function` property |

> **Important**: The Adams Python API is only available *inside* Adams View — it is not a standalone module and cannot be installed via `pip`.

## Skill file

[SKILL.md](SKILL.md) — load this file to activate the skill in your AI assistant.

## Reference structure

```
references/
├── naming-conventions.md                 Dot-path hierarchy, manager dict access, special chars
├── function-expressions.md               Master index for all FUNCTION= strings (same syntax as CMD)
└── api-classes/
    ├── model-parts-markers.md             Model, RigidBody, PointMass, FlexBody, Marker, defaults/units
    ├── constraints.md                     All joint types, JPrim primitives, Coupler, Gear, Motion, Friction
    ├── forces.md                          Gravity, SpringDamper, Bushing, Beam, SFORCE/VFORCE/GFORCE families
    ├── geometry.md                        Block, Cylinder, Ellipsoid, Frustum, Torus, Link, Arc, shell types
    ├── data-elements.md                   Spline 1D/2D, DesignVariable, StateVariable, Array, Matrix, Material
    ├── simulation-analysis.md             Simulations.create patterns, Analysis.results navigation, Measures
    ├── measures.md                        ObjectMeasure, Pt2pt, Angle, Orient, Function, Range, Point
    ├── contacts.md                        SolidToSolid and other contact types
    ├── system-elements.md                 DiffEq, TransferFunction, LSE, GSE, control loop pattern
    └── utilities.md                       Adams module attributes, expression/eval, execute_cmd, file I/O

references/adamspy-stubs/                  Git submodule — authoritative .pyi type stubs for all API classes
  (see https://github.com/bthornton191/adams-python-stubs)

assets/python_scripts/
├── simple_pendulum.py                     Single link, revolute joint, gravity  (port of CMD example)
├── parametric_chain.py                    N-link chain with Python for loop     (port of CMD example)
└── oscillating_slider.py                  Crank-slider with motion function and post-processing

evals/
└── evals.json                             Evaluation set for grading LLM output quality

scripts/
└── run_adams_python.py                    Run a .py file in Adams View batch mode and check for errors
```

## Using the type stubs

The `references/adamspy-stubs/` submodule contains `.pyi` stub files that document every class, property, and method in the Adams Python API. These are the authoritative signature reference when `SKILL.md` doesn't have a specific detail.

If you cloned this repo without `--recurse-submodules`, initialise the submodule:

```sh
git submodule update --init --recursive
```

## How to use

1. Open your AI assistant (GitHub Copilot, Claude, Cursor, etc.)
2. Add `SKILL.md` to context (attach the file or reference it in your prompt)
3. Ask your modelling question — e.g.:
   - *"Write a Python script to create a double wishbone suspension in Adams View"*
   - *"How do I parameterise a bushing stiffness using a design variable and Adams.expression()?"*
   - *"How do I read the contact force time history from Analysis.results?"*

## Running evals

The evals require an Adams View installation. Run a single eval:

```sh
python scripts/run_adams_python.py assets/python_scripts/simple_pendulum.py --timeout 120
```

For full eval grading, pass each generated `.py` file to the runner and capture the exit code and `aview.log`.
