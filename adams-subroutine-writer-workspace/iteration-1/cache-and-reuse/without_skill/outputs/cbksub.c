/**
 * cbksub.c
 *
 * Adams CBKSUB callback subroutine.
 * Caches the Y displacement of marker 5 w.r.t. ground marker 1
 * once per iteration, making it available to VFOSUB via get_cached_dy().
 */

#include "slv_c_utils.h"

/* ---------- shared cache ---------- */
static double g_cached_dy = 0.0;

/* Accessor used by vfosub (and any other sub) */
double get_cached_dy(void)
{
    return g_cached_dy;
}

/* ---------- CBKSUB entry point ---------- */
void cbksub(int *id, double *time, double *par, int *npar,
            int *flag, int *iflag)
{
    int    markers[2];
    int    nmarks = 2;
    int    errflg = 0;
    double dy     = 0.0;

    /*
     * Evaluate DY(5, 1)
     *   marker 5 = slider marker on part 2
     *   marker 1 = ground reference
     */
    markers[0] = 5;
    markers[1] = 1;

    c_sysfnc("DY", markers, nmarks, &dy, &errflg);

    if (errflg != 0) {
        *iflag = 1;          /* report error back to solver */
        return;
    }

    g_cached_dy = dy;        /* store for consumers */
    *iflag = 0;              /* success */
}
