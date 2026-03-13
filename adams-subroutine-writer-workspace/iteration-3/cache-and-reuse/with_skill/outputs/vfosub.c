/*
 * vfosub.c — Adams VFOSUB: linear spring using Y displacement cached by Cbksub
 *
 * PAR[0] — spring stiffness k  (force / length, in consistent model units)
 *
 * Applied force:
 *   result[0] = Fx = 0
 *   result[1] = Fy = -k * y_disp
 *   result[2] = Fz = 0
 *
 * The cached displacement from Cbksub is used directly during normal
 * evaluation passes (dflag == 0).  During finite-difference differencing
 * passes (dflag != 0) and dependency-mapping passes (iflag == 1 or 3) a
 * direct SYSARY call is made so the solver builds the correct Jacobian
 * sparsity pattern — the same marker arguments as Cbksub ensure consistency.
 *
 * .adm model snippet:
 *   VFORCE/1, I=5, JFLOAT=1001, RM=1
 *   , FUNCTION=USER(5000.0)        ! spring stiffness (example: 5000 N/mm)
 *   , ROUTINE=slider_sub:Vfosub
 *
 * The CBKSUB element must also be present in the .adm file:
 *   CBKSUB/1
 *   , ROUTINE=slider_sub:Cbksub
 */

#include "slv_c_utils.h"   /* sAdamsVforce, c_sysary, c_errmes, etc. */

/*
 * Cache populated by Cbksub at ev_ITERATION_BEG (defined in cbksub.c).
 * Declaring them extern here tells the linker to resolve them from cbksub.o
 * when both files are compiled into the same DLL.
 */
extern double g_slider_y_disp;
extern int    g_slider_cache_valid;

/* Forward declaration — lets the compiler type-check the signature below */
adams_c_Vfosub  Vfosub;


/*
 * Vfosub — vector force subroutine.
 *
 * Parameters (struct-based C interface):
 *   vfo     — VFORCE element metadata: ID, NPAR, PAR[], I, JFLOAT, RM
 *   time    — current simulation time (s)
 *   dflag   — 0 = normal evaluation,  1 = finite-difference differencing pass
 *   iflag   — evaluation context (see iflag guard comment below)
 *   result  — output array [Fx, Fy, Fz] — must be filled before returning
 */
void Vfosub( const struct sAdamsVforce *vfo, double time, int dflag, int iflag, double *result )
{
    double k = vfo->PAR[0];   /* spring stiffness supplied via USER() */

    /*
     * iflag guard — skip passes that do not evaluate forces:
     *   5 — expression destruction  (C++ novel expression framework only)
     *   7 — serialisation
     *   9 — unserialisation
     * Still proceed for iflag == 0 (normal), 1 (construction), 3 (dependency
     * mapping) — SYSARY calls during iflag 1 and 3 register the Jacobian
     * sparsity entries, which is why the fallback path below is required.
     */
    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    /*
     * Fast path — use the cached Y displacement.
     *
     * Conditions that must both be true:
     *   (a) dflag == 0: not a differencing pass (Adams perturbs states to
     *       compute partial derivatives; the cache is based on the unperturbed
     *       state so it cannot be used here)
     *   (b) g_slider_cache_valid == 1: Cbksub has already run ev_ITERATION_BEG
     *       for the current iteration and the cache holds a fresh value
     *
     * iflag == 1 or 3 will not reach this branch because g_slider_cache_valid
     * is 0 during those passes (Cbksub's unconditional invalidation at the top
     * of every call clears it before these passes).
     */
    if ( dflag == 0 && g_slider_cache_valid )
    {
        result[0] = 0.0;
        result[1] = -k * g_slider_y_disp;   /* Fy = -k * y */
        result[2] = 0.0;
        return;
    }

    /*
     * Fallback path — compute displacement directly via SYSARY.
     *
     * Required for:
     *   — differencing passes           (dflag != 0)
     *   — dependency-mapping passes     (iflag == 1 or 3)
     *   — any call before ev_ITERATION_BEG has fired (e.g. initial conditions)
     *
     * The marker arguments are identical to those in Cbksub so the solver
     * sees a consistent dependency graph and Jacobian sparsity pattern.
     *
     * SYSARY "DISP" ipar: [ marker_i, marker_j, result_frame ]
     *   ipar[0] = 5  — moving slider marker (part 2)
     *   ipar[1] = 1  — ground reference marker
     *   ipar[2] = 1  — express result in ground frame
     *
     * states[] layout returned: [ tx, ty, tz, rx, ry, rz ]
     *   states[1] = ty = Y translational displacement
     */
    {
        int    ipar[3] = { 5, 1, 1 };
        double states[6];
        int    nv, errflg;

        errflg = 0;
        c_sysary( "DISP", ipar, 3, states, &nv, &errflg );
        c_errmes( errflg, "c_sysary DISP failed in Vfosub", vfo->ID, "STOP" );

        result[0] = 0.0;
        result[1] = -k * states[1];   /* Fy = -k * y */
        result[2] = 0.0;
    }
}
