/*============================================================================
 * vfosub.c
 *
 * Adams/Solver VFORCE User Subroutine
 *
 * Description:
 *   Applies a linear spring force between marker 10 (moving) and marker 1
 *   (ground) using the law:
 *       Fx = -500 * (DX - 100)
 *   where DX is the X-displacement of marker 10 relative to marker 1
 *   (measured in the ground coordinate system by default).
 *
 * Force components are returned in the action marker frame (marker I = 10).
 *
 * Adams model statement:
 *   VFORCE/1, I=10, JFLOAT=1, FUNCTION=USER()
 *
 * Compilation: see build instructions in response.md
 *============================================================================*/

#include <stdio.h>
#include <string.h>

/*---------------------------------------------------------------------------
 * Platform DLL export macro
 *---------------------------------------------------------------------------*/
#ifdef _WIN32
#  define ADAMS_EXPORT __declspec(dllexport)
#else
#  define ADAMS_EXPORT
#endif

/*---------------------------------------------------------------------------
 * Adams/Solver C utility function prototypes.
 * These are provided by the Adams solver at link time; do NOT define them
 * yourself.  On Windows the solver exports them from the main exe/DLL.
 *---------------------------------------------------------------------------*/

/*
 * c_sysfnc - Evaluate an Adams system function (DX, DY, DZ, VX, AX, …)
 *
 *   sysnam  : null-terminated function name, e.g. "DX"
 *   ipar    : integer parameters (typically marker IDs)
 *   npar    : number of elements in ipar
 *   value   : [out] computed scalar result
 *   istat   : [out] 0 = success, non-zero = error
 */
extern void c_sysfnc(char   *sysnam,
                     int    *ipar,
                     int     npar,
                     double *value,
                     int    *istat);

/*
 * c_errmes - Issue an error/warning message through the solver message system
 *
 *   nerr   : severity (0=informational, 1=warning, 2=error/stop)
 *   msg    : null-terminated message string
 *   id     : pointer to the element ID for context, or NULL
 *   endflg : "STOP" to abort analysis, "NONE" to continue
 */
extern void c_errmes(int  *nerr,
                     char *msg,
                     int  *id,
                     char *endflg);


/*===========================================================================
 * VFOSUB
 *
 *   id     : [in]  Adams element ID of this VFORCE
 *   time   : [in]  current simulation time (seconds)
 *   par    : [in]  FUNCTION=USER( p1, p2, … ) parameter array (unused here)
 *   npar   : [in]  number of entries in par
 *   dflag  : [in]  derivative flag: 0 = value, 1 = partial derivatives
 *                  requested (ignored here — Adams uses finite-difference
 *                  linearisation by default)
 *   iflag  : [in]  initialisation flag: 1 on the very first call
 *   result : [out] 6-element array [Fx, Fy, Fz, Tx, Ty, Tz] in the I-marker
 *                  (action marker) frame
 *===========================================================================*/
ADAMS_EXPORT void vfosub(int    *id,
                         double *time,
                         double *par,
                         int    *npar,
                         int    *dflag,
                         int    *iflag,
                         double *result)
{
    /* ------------------------------------------------------------------
     * Marker IDs
     *   I-marker (action / moving) : 10
     *   J-marker (reaction / fixed): 1   (ground)
     * ------------------------------------------------------------------ */
    int    ipar[2] = { 10, 1 };

    double dx    = 0.0;
    int    istat = 0;

    /* ------------------------------------------------------------------
     * Retrieve X-displacement of marker 10 relative to marker 1.
     * "DX" returns the X-component of the position vector from marker J
     * to marker I, expressed in the ground (inertia) frame.
     * ------------------------------------------------------------------ */
    c_sysfnc("DX", ipar, 2, &dx, &istat);

    if (istat != 0)
    {
        int nerr = 2;
        char msg[] = "VFOSUB: failed to evaluate DX(10,1). Check marker IDs.";
        c_errmes(&nerr, msg, id, "STOP");
        return;
    }

    /* ------------------------------------------------------------------
     * Initialisation call — nothing extra required for a simple spring,
     * but the iflag branch is kept for clarity and future use.
     * ------------------------------------------------------------------ */
    if (*iflag == 1)
    {
        /* One-time setup could go here (e.g. open log files, allocate
         * thread-local storage via the Adams user-data pointer). */
    }

    /* ------------------------------------------------------------------
     * Linear spring law
     *   Fx = -k * (x - x0)  =  -500 * (DX - 100)
     *
     * Spring stiffness : k  = 500  [force/length, consistent with model units]
     * Free length       : x0 = 100 [length, consistent with model units]
     * ------------------------------------------------------------------ */
    result[0] = -500.0 * (dx - 100.0);   /* Fx  (spring force along X)   */
    result[1] =  0.0;                     /* Fy                           */
    result[2] =  0.0;                     /* Fz                           */
    result[3] =  0.0;                     /* Tx  (no torque)              */
    result[4] =  0.0;                     /* Ty                           */
    result[5] =  0.0;                     /* Tz                           */
}
