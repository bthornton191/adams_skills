/*
 * vfosub.c  –  Adams/Solver Vector Force Subroutine
 *
 * Purpose
 * -------
 * Applies a linear spring force along the Y-axis to the slider (marker 5,
 * part 2).  Rather than calling c_sysfnc("DY", ...) on every force
 * evaluation, it reads the Y-displacement that CBKSUB cached at the
 * beginning of the current time step.
 *
 * Adams model statement to attach this force
 * -------------------------------------------
 *   VFORCE/1, I=5, JFLOAT=1, RM=5, &
 *             FUNCTION=USER(k), &
 *             ROUTINE=USER_LIB::vfosub
 *
 * Where:
 *   I       = 5      – action marker (slider, part 2)
 *   JFLOAT  = 1      – reaction goes to ground
 *   RM      = 5      – force expressed in marker-5 frame
 *   USER(k) – passes stiffness k as par[0] (model force/length units)
 *
 * Compile / link
 * --------------
 * Compile cbksub.c and vfosub.c together into one shared library so the
 * linker can resolve the g_y_disp_cache symbol.  See response.md for full
 * build instructions.
 */

/* -----------------------------------------------------------------------
 * Shared displacement cache – defined in cbksub.c, read here.
 * ----------------------------------------------------------------------- */
extern double g_y_disp_cache;

/* -----------------------------------------------------------------------
 * VFOSUB
 *
 * Parameters
 * ----------
 * id      – VFORCE statement identifier
 * time    – current simulation time
 * par     – real parameters from FUNCTION=USER(...)
 *             par[0]  spring stiffness k  (force / length, model units)
 * npar    – number of entries in par
 * dflag   – 1 if Adams requests partial-derivative information
 * iflag   – phase flag (0 = normal evaluation; 1 = initialisation)
 * result  – output array: {Fx, Fy, Fz, Tx, Ty, Tz}
 * ----------------------------------------------------------------------- */
void VFOSUB(int    *id,
            double *time,
            double *par,
            int    *npar,
            int    *dflag,
            int    *iflag,
            double *result)
{
    double k  = par[0];           /* spring stiffness from Adams command  */
    double dy = g_y_disp_cache;   /* Y-displacement cached by CBKSUB      */

    /*
     * Simple linear spring: F_y = -k * DY
     *
     * The negative sign makes the force restoring (acts opposite to
     * displacement).  Adjust sign convention to match your model.
     */
    result[0] = 0.0;        /* Fx – no lateral force */
    result[1] = -k * dy;    /* Fy – restoring spring force along Y */
    result[2] = 0.0;        /* Fz */
    result[3] = 0.0;        /* Tx */
    result[4] = 0.0;        /* Ty */
    result[5] = 0.0;        /* Tz */
}
