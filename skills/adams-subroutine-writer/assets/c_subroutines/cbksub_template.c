/*
 * cbksub_template.c — Adams Solver CBKSUB skeleton (C)
 *
 * Build (Windows MSVC):
 *   cl /LD /I"%ADAMS_SDK%\sdk\include" /I"C:\Program Files\MSC.Software\Adams\2023_1\solver\c_usersubs" cbksub_template.c
 *       /link "%ADAMS_SDK%\sdk\lib\adams_util.lib"
 *
 * Or, copy slv_cbksub.h, slv_cbksub_util.h, slv_c_utils.h next to this file and omit the extra /I.
 *
 * Model file (.adm):
 *   CBKSUB/1
 *   , USER(1.0)
 *   , ROUTINE=cbksub_template:Cbksub
 */

#include "slv_c_utils.h"      /* all structs, c_sysary, c_errmes, c_usrmes, etc. */
#include "slv_cbksub.h"       /* ev_*, am_*, cm_*, sn_* enums                     */
#include "slv_cbksub_util.h"  /* get_event_name() helper (optional)               */

/*
 * Forward declaration using the typedef from slv_c_utils.h.
 * This lets the compiler type-check the function signature below.
 */
adams_c_Callback  Cbksub;

/*
 * Global cache — add fields here for values you want to cache
 * from ev_ITERATION_BEG for use in other user subroutines.
 */
static struct {
    double cached_value;    /* example cached result */
    int    valid;           /* 1 = cache contains fresh data, 0 = stale */
} g_cache;

/*
 * Cbksub — called by Adams at each simulation lifecycle event.
 *
 * Parameters:
 *   cbk   – element metadata (ID, NPAR, PAR[]); NULL on ev_INITIALIZE/ev_TERMINATE
 *   time  – current simulation time (seconds); undefined on ev_INITIALIZE
 *   event – event identifier (use ev_* constants — never raw integers)
 *   data  – event payload [3]; semantics depend on event (see cbksub.md)
 */
void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    /* Always invalidate cache at iteration boundary */
    g_cache.valid = 0;

    switch ( event )
    {
        /* -------------------------------------------------------
         * ev_INITIALIZE — called once before simulation begins.
         * time and cbk are undefined here.
         * Use for one-time allocations or external connections.
         * ------------------------------------------------------- */
        case ev_INITIALIZE:
            /* TODO: one-time initialization */
            break;

        /* -------------------------------------------------------
         * ev_TERMINATE — called once after simulation ends.
         * data[0] = solver exit status.
         * Use for cleanup, file flush, etc.
         * ------------------------------------------------------- */
        case ev_TERMINATE:
            /* TODO: cleanup */
            break;

        /* -------------------------------------------------------
         * ev_ITERATION_BEG — called at the start of each Newton
         * iteration.  This is the primary caching point.
         *
         * data[0] = simulation mode  (am_DYNAMICS, am_STATICS, ...)
         * data[1] = analysis mode    (am_*)
         * data[2] = 1 if Jacobian/partial derivative is needed
         * ------------------------------------------------------- */
        case ev_ITERATION_BEG:
        {
            int    ipar[3], nv, errflg;
            double states[6];

            /* Example: cache marker 16 displacement relative to marker 1
             * expressed in marker 1's frame.
             * Replace marker IDs and computation with your actual logic.
             */
            ipar[0] = 16;   /* moving marker ID */
            ipar[1] = 1;    /* reference marker ID */
            ipar[2] = 1;    /* result frame marker ID */
            errflg  = 0;

            c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
            if ( errflg )
            {
                int id = cbk ? cbk->ID : 0;
                c_errmes( &errflg, "c_sysary DISP failed in Cbksub", &id, "STOP" );
                return;
            }

            g_cache.cached_value = -states[1] * 30.0;  /* example: Fy = -k*y */
            g_cache.valid        = 1;
            break;
        }

        /* -------------------------------------------------------
         * ev_STATICS_END — called after each static analysis.
         * data[2] = 0 if converged, 1 if failed.
         * ------------------------------------------------------- */
        case ev_STATICS_END:
            if ( data[2] == 1 )
            {
                /* statics failed to converge — log or handle */
            }
            break;

        /* -------------------------------------------------------
         * ev_SENSOR — triggered when an Adams SENSOR fires.
         * data[0] = sensor element ID
         * data[1] = sensor action type (sn_HALT, sn_PRINT, ...)
         * ------------------------------------------------------- */
        case ev_SENSOR:
            /* TODO: respond to sensor event if needed */
            break;

        /* -------------------------------------------------------
         * ev_COMMAND — triggered when an Adams command is issued.
         * data[0] = command identifier (cm_SIMULATE, cm_STOP, ...)
         * data[1] = 1 if issued from CONSUB, 0 otherwise
         * ------------------------------------------------------- */
        case ev_COMMAND:
            if ( data[0] == cm_SIMULATE )
            {
                /* about to run a simulation */
            }
            break;

        /* -------------------------------------------------------
         * PRIVATE EVENTS — must always be ignored.
         * Never read data[] for these events.
         * ------------------------------------------------------- */
        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;

        default:
            /* Ignore any events not handled above */
            break;
    }
}
