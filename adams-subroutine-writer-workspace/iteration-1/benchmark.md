# Benchmark: adams-subroutine-writer — Iteration 1

## Summary

| Configuration | Pass Rate | Evals |
|---|---|---|
| **with_skill** | **100%** (22/22) | 3 |
| without_skill | 27.3% (6/22) | 3 |
| **Delta** | **+72.7%** | — |

## Per-Eval Breakdown

### cache-and-reuse (9 assertions)
| | with_skill | without_skill |
|---|---|---|
| Pass rate | 100% (9/9) | 11% (1/9) |

Without-skill used Fortran-style flat params, no event handling, no iflag guard, no dflag awareness, no c_errmes. Only got slv_c_utils.h include correct.

### forbidden-call-trap (5 assertions)
| | with_skill | without_skill |
|---|---|---|
| Pass rate | 100% (5/5) | 40% (2/5) |

Without-skill presented calling VFOSUB directly from CBKSUB as the primary approach (a runtime crash), used raw integer `case 4` instead of `ev_ITERATION_BEG`, but did mention c_sysary and the caching alternative as a secondary option.

### vfosub-spring-force (8 assertions)
| | with_skill | without_skill |
|---|---|---|
| Pass rate | 100% (8/8) | 37.5% (3/8) |

Without-skill used Fortran-style signature with trailing underscore, no iflag guard, hardcoded markers, wrong library name (`adams_utils.lib`). Got slv_c_utils.h, c_sysfnc, and c_errmes correct.

## Analyst Observations

1. **Non-discriminating assertion**: `slv_c_utils.h` include passes 100% in both configs — doesn't measure skill value.
2. **Most discriminating patterns** (0% baseline): struct-based C signature, iflag guard, ev_PRIVATE handling, dflag awareness, PAR[] parameterization.
3. **Partial baseline knowledge**: The model knows `c_sysary`/`c_sysfnc`/`c_errmes` exist (2-3/3 partial pass without skill), but lacks the correct calling conventions and guard patterns.
4. **Biggest single fix**: The skill eliminates the Fortran-style flat parameter signature — the baseline consistently generates this wrong pattern.
5. **Timing not captured**: Subagent timing was not recorded; re-run with timing capture needed for cost analysis.
