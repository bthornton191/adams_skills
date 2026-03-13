/*
 * vfosub.c — VFOSUB that consumes the force cache populated by Cbksub.
 *
 * At the start of each Newton iteration, Cbksub fires ev_ITERATION_BEG
 * and computes the force into g_vfo_cache.  When Adams then calls Vfosub
 * for a normal (non-differencing) evaluation, we return the cached result
 * directly without querying c_sysary again.
 *
 * For differencing passes (dflag != 0) the solver needs slightly perturbed
 * state values, so we always call c_sysary directly in that case.
 *
 * Build (together with cbksub.c):
 *   mdi.bat cr-u n cbksub.c vfosub.c -n my_forces.dll ex
 *
 * Model file (.adm):
 *   VFORCE/1
 *   , I=101
 *   , JFLOAT=201
 *   , RM=101
 *   , FUNCTION=USER(500.0, 101, 1, 1)   $ PAR[0]=k, PAR[1..3]=marker IDs
 *   , ROUTINE=my_forces:Vfosub
 */

#include "slv_c_utils.h"    /* c_sysary, c_errmes, sAdamsVforce, adams_c_Vfosub */

/* ------------------------------------------------------------------
 * g_vfo_cache — defined in cbksub.c; extern-declared here so both
 * translation units share the same storage when linked into one DLL.
 * ------------------------------------------------------------------ */
typedef struct {
    double fx;
    double fy;
    double fz;
    int    valid;
} VfoCache;

extern VfoCache g_vfo_cache;

/* Forward declaration for compiler type-checking. */
adams_c_Vfosub  Vfosub;

/*
 * Vfosub — 3-component vector force subroutine.
 *
 *   vfo    — element metadata (ID, NPAR, PAR[])
 *   time   — current simulation time (seconds)
 *   dflag  — 1 during finite-difference Jacobian computation, 0 otherwise
 *   iflag  — evaluation mode (see guard below)
 *   result — output force [fx, fy, fz] (N)
 */
void Vfosub( const struct sAdamsVforce *vfo, double time, int dflag, int iflag, double *result )
{
    int    ipar[3], nv, errflg;
    double disp[6];
    double k;

    /* ----------------------------------------------------------
     * iflag guard — mandatory before any c_sysary/c_sysfnc call.
     *
     * iflag == 5: expression destruction  (C++ only) — skip
     * iflag == 7: serialisation           — skip
     * iflag == 9: unserialisation         — skip
     *
     * iflag == 0: normal evaluation       — proceed
     * iflag == 1: expression construction — proceed (same calls as normal)
     * iflag == 3: dependency mapping      — proceed (builds Jacobian sparsity)
     * ---------------------------------------------------------- */
    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    /* ----------------------------------------------------------
     * Use the CBKSUB cache on clean (non-differencing) iterations.
     *
     * Skip the cache when:
     *   dflag != 0 — solver is perturbing states for Jacobian
     *   !g_vfo_cache.valid — Cbksub has not yet populated the cache
     *     (e.g., during initial conditions before first iteration)
     * ---------------------------------------------------------- */
    if ( dflag == 0 && g_vfo_cache.valid )
    {
        result[0] = g_vfo_cache.fx;
        result[1] = g_vfo_cache.fy;
        result[2] = g_vfo_cache.fz;
        return;
    }

    /* ----------------------------------------------------------
     * Fallback: compute force directly from solver state.
     * This path is taken:
     *   - during differencing (dflag != 0)
     *   - during dependency-mapping passes (iflag == 1 or 3)
     *   - if cache is stale for any other reason
     *
     * The formula here must be identical to the one in Cbksub.
     * ---------------------------------------------------------- */

    /* PAR[0] = spring stiffness k (N/mm)
     * PAR[1] = moving marker ID, PAR[2] = reference marker ID,
     * PAR[3] = result frame marker ID                          */
    k       = vfo->PAR[0];
    ipar[0] = (int)vfo->PAR[1];   /* moving marker */
    ipar[1] = (int)vfo->PAR[2];   /* reference marker */
    ipar[2] = (int)vfo->PAR[3];   /* result frame marker */
    errflg  = 0;

    c_sysary( "DISP", ipar, 3, disp, &nv, &errflg );
    c_errmes( &errflg, "c_sysary DISP failed in Vfosub", &vfo->ID, "STOP" );

    /* disp[0]=tx, disp[1]=ty, disp[2]=tz */
    result[0] = -k * disp[0];
    result[1] = -k * disp[1];
    result[2] = -k * disp[2];
}
