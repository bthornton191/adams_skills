/*
 * vfosub.c — VFORCE subroutine that reads the cached Y displacement
 *            from CBKSUB instead of recomputing it every evaluation.
 *
 * Model file (.adm):
 *   VFORCE/1
 *   , I = 5
 *   , JFLOAT = 1
 *   , RM = 1
 *   , FX = 0   \   ignored when USER() is present,
 *   , FY = 0    >  but required syntactically
 *   , FZ = 0   /
 *   , USER(30.0, 5.0, 1.0)
 *   , ROUTINE=my_sub:Vfosub
 *
 *   USER(1) = spring stiffness k
 *   USER(2) = moving marker  (5)
 *   USER(3) = reference marker (1, ground)
 */

#include "slv_c_utils.h"

adams_c_Vfosub  Vfosub;

/* Declared in cbksub.c — populated at ev_ITERATION_BEG */
extern double g_cached_y_disp;
extern int    g_cache_valid;

void Vfosub( const struct sAdamsVforce *vfo, double time,
             int dflag, int iflag, double *result )
{
    double k       = vfo->PAR[0];          /* spring stiffness    */
    int    mkr_i   = (int)vfo->PAR[1];     /* moving marker  (5)  */
    int    mkr_ref = (int)vfo->PAR[2];     /* ground marker  (1)  */

    /* Skip non-evaluation passes */
    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    /*
     * During normal evaluation (dflag==0), reuse the cached value
     * that CBKSUB stored at ev_ITERATION_BEG.
     *
     * During finite-differencing (dflag==1) or dependency mapping
     * (iflag==1 or 3), we MUST call c_sysary so the solver can
     * see VFOSUB's dependency on marker 5's state and build the
     * correct Jacobian sparsity pattern.
     */
    if ( dflag == 0 && g_cache_valid )
    {
        result[0] = 0.0;
        result[1] = -k * g_cached_y_disp;   /* Fy = -k * y */
        result[2] = 0.0;
        return;
    }

    /* Fallback: compute directly (differencing or cache miss) */
    {
        int    ipar[3], nv, errflg;
        double states[6];

        ipar[0] = mkr_i;
        ipar[1] = mkr_ref;
        ipar[2] = mkr_ref;
        errflg  = 0;

        c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
        c_errmes( errflg, "c_sysary DISP failed in Vfosub", vfo->ID, "STOP" );

        result[0] = 0.0;
        result[1] = -k * states[1];   /* Fy = -k * y */
        result[2] = 0.0;
    }
}
