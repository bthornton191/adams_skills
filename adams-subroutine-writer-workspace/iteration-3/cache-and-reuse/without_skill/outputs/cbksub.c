/*
 * cbksub.c  –  Adams/Solver Callback Subroutine
 *
 * Purpose
 * -------
 * Called by Adams/Solver at key simulation phases.  On the flag that
 * marks the beginning of each new time step the subroutine queries the
 * Y-displacement of marker 5 (slider, on part 2) relative to marker 1
 * (ground reference) and stores the result in a file-scope variable.
 * VFOSUB reads that variable directly, avoiding a redundant solver
 * function call on every force evaluation within the same step.
 *
 * Adams model statement to activate this subroutine
 * --------------------------------------------------
 *   CBKSUB/1, ROUTINE=USER_LIB::cbksub
 *
 * (Use the EXECUTIVE/CBKSUB variant if your Adams version requires it.)
 *
 * Compile / link
 * --------------
 * See build instructions in response.md.
 */

#include <string.h>   /* memset */

/* -----------------------------------------------------------------------
 * Shared displacement cache
 * Declared here (definition); vfosub.c references it via "extern".
 * ----------------------------------------------------------------------- */
double g_y_disp_cache = 0.0;

/* -----------------------------------------------------------------------
 * Adams/Solver C utility – evaluate a named system function.
 *
 * Prototype matches the Adams SDK header <slv_c_utils.h>.
 * Include that header instead of this declaration if it is on your
 * include path.
 * ----------------------------------------------------------------------- */
extern void c_sysfnc(char   *sysnam,  /* Adams function name, e.g. "DY"  */
                     int    *ipar,    /* integer parameter array           */
                     int    *nsipar,  /* number of integers in ipar        */
                     double *states,  /* output value(s) written here      */
                     int    *errflg); /* 0 = success, non-zero = error     */

/* -----------------------------------------------------------------------
 * CBKSUB
 *
 * Signature follows the Adams/Solver C user-subroutine convention.
 *
 * Parameters
 * ----------
 * id      – CBKSUB statement identifier
 * time    – current simulation time (seconds / model time units)
 * par     – real parameters supplied on the CBKSUB statement
 * npar    – number of real parameters
 * dflag   – 1 if Adams needs partial derivatives; 0 otherwise
 * iflag   – simulation phase code (see table below)
 *
 * iflag values (MSC Adams/Solver 2020+)
 * --------------------------------------
 *   0  – model verification / static equilibrium initialisation
 *   1  – start of quasi-static or static analysis
 *   2  – start of each dynamic time step  <-- we act on this one
 *   3  – after every Newton–Raphson iteration has converged
 *   4  – end of step (after output has been written)
 *   5  – end of simulation
 *
 * NOTE: Exact iflag semantics vary across Adams releases.  Verify
 *       the values against the "User-Written Subroutines" chapter
 *       of your Adams/Solver release notes before deploying.
 * ----------------------------------------------------------------------- */
void CBKSUB(int    *id,
            double *time,
            double *par,
            int    *npar,
            int    *dflag,
            int    *iflag)
{
    int    ipar_fn[3];
    int    nsipar  = 3;
    double dy_val  = 0.0;
    int    errflg  = 0;

    /*
     * Only refresh the cache at the beginning of each time step
     * (iflag == 2).  All VFOSUB evaluations within the step then
     * share a single consistent DY reading.
     *
     * Change to iflag == 3 if you need the value updated after every
     * converged iteration instead.
     */
    if (*iflag != 2)
        return;

    /* DY(I, J, K):
     *   I = 5  – slider marker on part 2
     *   J = 1  – ground reference marker
     *   K = 0  – express result in the ground (global) frame
     */
    ipar_fn[0] = 5;   /* marker I */
    ipar_fn[1] = 1;   /* marker J */
    ipar_fn[2] = 0;   /* reference frame K: 0 = ground */

    c_sysfnc("DY", ipar_fn, &nsipar, &dy_val, &errflg);

    if (errflg == 0)
    {
        g_y_disp_cache = dy_val;
    }
    /*
     * If c_sysfnc returns an error (e.g. markers not yet initialised)
     * the previous cached value is intentionally preserved.
     */
}
