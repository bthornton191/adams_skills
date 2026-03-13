/*
 * cbksub.c — Adams CBKSUB: caches slider Y displacement once per iteration
 *
 * Model: slider with marker 5 (part 2) and ground marker 1.
 *
 * At ev_ITERATION_BEG the Y displacement of marker 5, measured from marker 1
 * and expressed in the marker 1 (ground) frame, is stored in the file-scope
 * globals below.  Vfosub reads these instead of issuing a redundant SYSARY
 * call on every force evaluation in the same iteration.
 *
 * Build (Windows — agent workflow):
 *   python scripts/generate_adams_env.py
 *   call "%LOCALAPPDATA%\adams_env_init.bat"
 *   mdi.bat cr-u n cbksub.c vfosub.c -n slider_sub.dll ex
 *
 * .adm model snippet:
 *   CBKSUB/1
 *   , ROUTINE=slider_sub:Cbksub
 */

#include "slv_c_utils.h"      /* all structs, c_sysary, c_errmes, c_usrmes, etc. */
#include "slv_cbksub.h"       /* ev_*, am_*, cm_*, sn_* enums                     */
#include "slv_cbksub_util.h"  /* get_event_name() helper (optional)               */

/* Forward declaration — lets the compiler type-check the signature below */
adams_c_Callback  Cbksub;

/*
 * Shared cache — populated at ev_ITERATION_BEG.
 * Both globals are non-static so vfosub.c can declare them with 'extern'
 * and read them without a second SYSARY call.
 */
double g_slider_y_disp    = 0.0; /* Y displacement of marker 5 w.r.t. marker 1   */
int    g_slider_cache_valid = 0; /* 1 = fresh this iteration,  0 = stale / unset */


/*
 * Cbksub — called by Adams at each simulation lifecycle event.
 *
 * Parameters:
 *   cbk   — element metadata (ID, NPAR, PAR[]); NULL on ev_INITIALIZE / ev_TERMINATE
 *   time  — current simulation time (s); undefined on ev_INITIALIZE
 *   event — event identifier; always use ev_* constants, never raw integers
 *   data  — event payload [3]; semantics depend on event (see cbksub.md)
 */
void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    /*
     * Invalidate the cache unconditionally at the top of every call.
     * This guarantees the cache is never read with stale data should the
     * caller somehow not reach the ev_ITERATION_BEG branch (e.g. during
     * initialisation or linear analysis).
     */
    g_slider_cache_valid = 0;

    switch ( event )
    {
        /* ------------------------------------------------------------------
         * ev_INITIALIZE — fired once before the simulation begins.
         * cbk and time are undefined; use for one-time setup only.
         * ------------------------------------------------------------------ */
        case ev_INITIALIZE:
            /* Nothing to initialise — globals already zero-initialised */
            break;

        /* ------------------------------------------------------------------
         * ev_TERMINATE — fired once after the simulation ends.
         * data[0] = solver exit status (0 = clean exit).
         * ------------------------------------------------------------------ */
        case ev_TERMINATE:
            /* Nothing to clean up */
            break;

        /* ------------------------------------------------------------------
         * ev_ITERATION_BEG — fired at the start of each Newton iteration.
         *
         *   data[0] = simulation mode  (am_DYNAMICS, am_STATICS, ...)
         *   data[1] = analysis mode    (am_*)
         *   data[2] = 1 if a Jacobian / partial-derivative pass is requested
         *
         * This is the primary caching point.  Query SYSARY once here and
         * let Vfosub (and any other force sub) reuse the result.
         *
         * SYSARY "DISP" ipar layout: [ marker_i, marker_j, result_frame ]
         *   ipar[0] = 5 — moving marker on the slider body (part 2)
         *   ipar[1] = 1 — reference marker (ground)
         *   ipar[2] = 1 — express result in the marker 1 (ground) frame
         *
         * Returned states[] layout: [ tx, ty, tz, rx, ry, rz ]
         *   states[1] = ty = Y translational displacement  ← what we cache
         * ------------------------------------------------------------------ */
        case ev_ITERATION_BEG:
        {
            int    ipar[3] = { 5, 1, 1 };
            double states[6];
            int    nv, errflg;

            errflg = 0;
            c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
            if ( errflg )
            {
                int id = cbk ? cbk->ID : 0;
                c_errmes( errflg, "c_sysary DISP failed in Cbksub", id, "STOP" );
                return;
            }

            g_slider_y_disp     = states[1];
            g_slider_cache_valid = 1;
            break;
        }

        /* ------------------------------------------------------------------
         * PRIVATE EVENTS — must always be silently ignored.
         * Never inspect data[] for these events.
         * ------------------------------------------------------------------ */
        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;

        default:
            break;
    }
}
