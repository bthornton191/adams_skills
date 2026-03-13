/*
 * cbksub.c — CBKSUB that pre-calculates VFOSUB forces at ev_ITERATION_BEG.
 *
 * The solver forbids CBKSUB from calling VFOSUB directly.  Instead, call
 * c_sysary() here with the same state query the force calculation needs,
 * compute the result, and store it in g_vfo_cache.  Vfosub() reads from
 * that cache on the next (non-differencing) evaluation of the same iteration.
 *
 * Build:
 *   call "%LOCALAPPDATA%\adams_env_init.bat"
 *   mdi.bat cr-u n cbksub.c vfosub.c -n my_forces.dll ex
 *
 * Model file (.adm):
 *   CBKSUB/1
 *   , USER(500.0)            $ PAR[0] = spring stiffness k (N/mm)
 *   , ROUTINE=my_forces:Cbksub
 */

#include "slv_c_utils.h"      /* c_sysary, c_errmes, utility fn decls */
#include "slv_cbksub.h"       /* ev_*, am_*, cm_*, sn_* enums          */
#include "slv_cbksub_util.h"  /* get_event_name() helper (optional)    */

/* ------------------------------------------------------------------
 * Shared force cache.
 *
 * Defined here (cbksub.c) with external linkage so that vfosub.c can
 * access it via an extern declaration.  Both files must be compiled
 * into the same DLL.
 * ------------------------------------------------------------------ */
typedef struct {
    double fx;      /* pre-calculated force components (N) */
    double fy;
    double fz;
    int    valid;   /* 1 = cache holds fresh data for this iteration */
} VfoCache;

VfoCache g_vfo_cache = { 0.0, 0.0, 0.0, 0 };

/* Forward declaration — lets the compiler type-check the signature. */
adams_c_Callback  Cbksub;

/*
 * Cbksub — called by Adams at each simulation lifecycle event.
 *
 *   cbk   — element metadata (ID, NPAR, PAR[]); NULL on ev_INITIALIZE/ev_TERMINATE
 *   time  — current simulation time (seconds); undefined on ev_INITIALIZE
 *   event — event identifier (always use ev_* constants — never raw integers)
 *   data  — event payload [3]; semantics depend on event
 */
void Cbksub( const struct sAdamsCbksub *cbk, double time, int event, int *data )
{
    /* Invalidate the cache at every event boundary so that a stale
     * value is never accidentally used across iteration boundaries. */
    g_vfo_cache.valid = 0;

    switch ( event )
    {
        /* ----------------------------------------------------------
         * ev_ITERATION_BEG — fires at the start of every Newton
         * iteration.  This is the correct place to pre-calculate
         * forces for use by Vfosub during the same iteration.
         *
         * data[0] = simulation mode  (am_DYNAMICS, am_STATICS, …)
         * data[1] = analysis mode    (am_*)
         * data[2] = 1 if a Jacobian/partial-derivative pass follows
         * ---------------------------------------------------------- */
        case ev_ITERATION_BEG:
        {
            int    ipar[3], nv, errflg;
            double disp[6];
            double k;
            int    id = cbk ? cbk->ID : 0;

            /* Spring stiffness from CBKSUB USER() parameter list.
             * Must match the value used in VFORCE/USER().           */
            k = cbk->PAR[0];

            /* Query displacement of marker 101 relative to marker 1,
             * expressed in frame of marker 1.
             * Replace these IDs with your actual model markers.      */
            ipar[0] = 101;  /* moving marker */
            ipar[1] = 1;    /* reference marker */
            ipar[2] = 1;    /* result frame marker */
            errflg  = 0;

            c_sysary( "DISP", ipar, 3, disp, &nv, &errflg );
            if ( errflg )
            {
                c_errmes( &errflg, "c_sysary DISP failed in Cbksub", &id, "STOP" );
                return;
            }

            /* Compute force — identical formula to Vfosub's fallback path.
             * disp[0]=tx, disp[1]=ty, disp[2]=tz (metres).              */
            g_vfo_cache.fx    = -k * disp[0];
            g_vfo_cache.fy    = -k * disp[1];
            g_vfo_cache.fz    = -k * disp[2];
            g_vfo_cache.valid = 1;
            break;
        }

        case ev_INITIALIZE:
            /* One-time setup if needed. cbk is NULL here. */
            break;

        case ev_TERMINATE:
            /* Cleanup if needed. cbk is NULL here. data[0] = exit status. */
            break;

        /* ----------------------------------------------------------
         * PRIVATE EVENTS — must always be ignored.
         * Never read data[] for these events.
         * ---------------------------------------------------------- */
        case ev_PRIVATE_EVENT1:
        case ev_PRIVATE_EVENT2:
            return;

        default:
            break;
    }
}
