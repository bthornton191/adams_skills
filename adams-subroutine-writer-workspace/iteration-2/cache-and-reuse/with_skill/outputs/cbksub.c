/*
 * cbksub.c — CBKSUB that caches slider Y displacement once per iteration.
 *
 * The solver calls Cbksub at ev_ITERATION_BEG before evaluating any forces.
 * We use c_sysary("TDISP") to grab the Y translation of marker 5 relative
 * to ground marker 1, then store it in a file-scope cache that Vfosub reads.
 *
 * Build:
 *   Windows: mdi.bat cr-u n cbksub.c vfosub.c -n my_sub.dll ex
 *   Linux:   mdi -c cr-u n cbksub.c vfosub.c -n my_sub.so ex
 *
 * Model file (.adm):
 *   CBKSUB/1
 *   , USER(5.0, 1.0)
 *   , ROUTINE=my_sub:Cbksub
 */

#include "slv_c_utils.h"
#include "slv_cbksub.h"
#include "slv_cbksub_util.h"

adams_c_Callback  Cbksub;

/* ---------------------------------------------------------------
 * Shared cache — Vfosub reads these via extern declarations.
 * g_cached_dy   : Y displacement of marker 5 w.r.t. marker 1
 * g_cache_valid : 1 after a successful update, 0 otherwise
 * --------------------------------------------------------------- */
double g_cached_dy    = 0.0;
int    g_cache_valid  = 0;

void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    /* Invalidate at every event so stale data is never consumed */
    g_cache_valid = 0;

    switch ( event )
    {
        case ev_INITIALIZE:
            g_cached_dy   = 0.0;
            g_cache_valid = 0;
            break;

        case ev_TERMINATE:
            break;

        /* ----------------------------------------------------------
         * ev_ITERATION_BEG — fired once at the start of each Newton
         * iteration, before any force subroutines are evaluated.
         *
         * data[0] = simulation mode  (am_DYNAMICS, am_STATICS, …)
         * data[1] = analysis mode
         * data[2] = 1 if Jacobian pass
         * ---------------------------------------------------------- */
        case ev_ITERATION_BEG:
        {
            int    ipar[3], nv, errflg;
            double tdisp[3];          /* tx, ty, tz */

            /* Marker 5 translation relative to ground marker 1,
               expressed in marker 1's frame.                       */
            ipar[0] = (int)( cbk->PAR[0] );   /* moving marker  (5) */
            ipar[1] = (int)( cbk->PAR[1] );   /* ref marker     (1) */
            ipar[2] = (int)( cbk->PAR[1] );   /* result frame   (1) */
            errflg  = 0;

            c_sysary( "TDISP", ipar, 3, tdisp, &nv, &errflg );
            if ( errflg )
            {
                int id = cbk ? cbk->ID : 0;
                c_errmes( &errflg, "c_sysary TDISP failed in Cbksub", &id, "STOP" );
                return;
            }

            g_cached_dy   = tdisp[1];   /* Y component */
            g_cache_valid = 1;
            break;
        }

        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;   /* Must ignore — never read data[] */

        default:
            break;
    }
}
