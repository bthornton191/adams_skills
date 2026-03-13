/*
 * cbksub.c — Caches Y displacement of slider marker 5 relative to ground
 *            marker 1 at ev_ITERATION_BEG so VFOSUB can reuse it cheaply.
 *
 * Build (Windows MSVC):
 *   cl /LD /I"%ADAMS_SDK%\sdk\include" cbksub.c vfosub.c ^
 *      /link "%ADAMS_SDK%\sdk\lib\adams_util.lib" /OUT:my_sub.dll
 *
 * Model file (.adm):
 *   CBKSUB/1
 *   , USER(5.0, 1.0)
 *   , ROUTINE=my_sub:Cbksub
 *
 *   USER(1) = moving marker ID  (5)
 *   USER(2) = reference marker  (1, ground)
 */

#include "slv_c_utils.h"
#include "slv_cbksub.h"
#include "slv_cbksub_util.h"

adams_c_Callback  Cbksub;

/* ---- Shared cache (accessed by Vfosub via extern) ---- */
double g_cached_y_disp = 0.0;
int    g_cache_valid   = 0;

void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    /* Invalidate at every entry — only set valid inside ev_ITERATION_BEG */
    g_cache_valid = 0;

    switch ( event )
    {
        case ev_INITIALIZE:
            g_cached_y_disp = 0.0;
            break;

        case ev_TERMINATE:
            break;

        case ev_ITERATION_BEG:
        {
            int    ipar[3], nv, errflg;
            double states[6];

            /* Read USER() params: marker IDs for the slider/ground pair */
            ipar[0] = (int)cbk->PAR[0];   /* moving marker  (5) */
            ipar[1] = (int)cbk->PAR[1];   /* reference marker (1, ground) */
            ipar[2] = (int)cbk->PAR[1];   /* express result in ground frame */
            errflg  = 0;

            c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
            if ( errflg )
            {
                c_errmes( errflg, "c_sysary DISP failed in Cbksub", cbk->ID, "STOP" );
                return;
            }

            /* states[0]=x, states[1]=y, states[2]=z, [3..5]=rotations */
            g_cached_y_disp = states[1];
            g_cache_valid   = 1;
            break;
        }

        /* Must always ignore private events — never read data[] */
        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;

        default:
            break;
    }
}
