/*
 * vfosub.c — VFOSUB that reads the cached Y displacement from Cbksub.
 *
 * On a normal evaluation pass (dflag == 0) with a valid cache, the
 * subroutine returns the spring force directly from g_cached_dy,
 * avoiding a redundant c_sysary call.
 *
 * During finite-differencing (dflag == 1) or when the cache is stale,
 * it falls back to a live c_sysary("TDISP") call so that the solver
 * can compute correct partial derivatives.
 *
 * Build (together with cbksub.c):
 *   Windows: mdi.bat cr-u n cbksub.c vfosub.c -n my_sub.dll ex
 *   Linux:   mdi -c cr-u n cbksub.c vfosub.c -n my_sub.so ex
 *
 * Model file (.adm):
 *   VFORCE/1
 *   , I = 5
 *   , JFLOAT = 1
 *   , RM = 1
 *   , FX = 0.0
 *   , FY = 0.0
 *   , FZ = 0.0
 *   , USER(5.0, 1.0, 100.0)
 *   , ROUTINE=my_sub:Vfosub
 */

#include "slv_c_utils.h"

adams_c_Vfosub  Vfosub;

/* Cache populated by Cbksub at ev_ITERATION_BEG (defined in cbksub.c) */
extern double g_cached_dy;
extern int    g_cache_valid;

void Vfosub( const struct sAdamsVforce *vfo, double time,
             int dflag, int iflag, double *result )
{
    int    marker_i, marker_j;
    double stiffness;

    /* Skip non-evaluation passes (expression destroy / serialize) */
    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    /* Read USER() parameters */
    marker_i  = (int)( vfo->PAR[0] );   /* moving marker   (5) */
    marker_j  = (int)( vfo->PAR[1] );   /* reference marker(1) */
    stiffness = vfo->PAR[2];            /* spring constant (k) */

    /* ----------------------------------------------------------
     * Use cached DY when:
     *   1. iflag == 0 (normal evaluation — not dependency mapping)
     *   2. Cache is valid (populated this iteration by Cbksub)
     *   3. dflag == 0 (nominal evaluation, not finite-differencing)
     *
     * During dependency mapping (iflag == 3) the solver needs to
     * see the c_sysary call to build the Jacobian sparsity pattern.
     * During finite-differencing (dflag == 1) the solver perturbs
     * states, so we must call c_sysary to pick up the perturbed
     * displacement.
     * ---------------------------------------------------------- */
    if ( iflag == 0 && dflag == 0 && g_cache_valid )
    {
        result[0] = 0.0;
        result[1] = -stiffness * g_cached_dy;
        result[2] = 0.0;
        return;
    }

    /* Fallback: compute displacement directly */
    {
        int    ipar[3], nv, errflg;
        double tdisp[3];

        ipar[0] = marker_i;
        ipar[1] = marker_j;
        ipar[2] = marker_j;
        errflg  = 0;

        c_sysary( "TDISP", ipar, 3, tdisp, &nv, &errflg );
        {
            int elem_id = vfo->ID;
            c_errmes( &errflg, "c_sysary TDISP failed in Vfosub", &elem_id, "STOP" );
        }

        result[0] = 0.0;
        result[1] = -stiffness * tdisp[1];
        result[2] = 0.0;
    }
}
