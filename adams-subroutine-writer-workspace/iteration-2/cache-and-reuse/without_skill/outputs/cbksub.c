/**
 * cbksub.c
 *
 * CALLBACK subroutine that evaluates DY(5,1) once per iteration
 * and stores the result in a global variable so that VFOSUB (and
 * any other user subroutine) can read the cached value without
 * redundant solver-function calls.
 *
 * Adams dataset usage:
 *   CALLBACK/1
 *   , ROUTINE = cbksub
 *   , FUNCTION = USER(0)
 *   , CALLBACK_EVENT = CORRECTOR_PASS
 */

#include "slv_c_utils.h"

/* ------------------------------------------------------------------ */
/* Shared cache – written by CBKSUB, read by VFOSUB                   */
/* ------------------------------------------------------------------ */
double cached_dy_marker5 = 0.0;

void cbksub_(int *id, double *time, double *par, int *npar,
             int *istate, int *nflag, int *errflg)
{
    double args[2];
    int    nargs = 2;

    *errflg = 0;

    /*
     * Evaluate DY(5, 1)
     *   arg[0] = 5  -> "to" marker  (slider, on part 2)
     *   arg[1] = 1  -> "from" marker (ground)
     */
    args[0] = 5.0;
    args[1] = 1.0;

    c_sysfnc("DY", args, &nargs, &cached_dy_marker5, errflg);

    if (*errflg != 0) {
        c_errmes(1, "Error in CBKSUB: c_sysfnc(DY) failed", *id, "CBKSUB");
    }
}
