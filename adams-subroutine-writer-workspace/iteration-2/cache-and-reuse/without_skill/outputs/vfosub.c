/**
 * vfosub.c
 *
 * VFORCE subroutine that reads the cached Y-displacement value
 * computed by CBKSUB instead of calling c_sysfnc itself.
 *
 * Adams dataset usage:
 *   VFORCE/1
 *   , I = 5
 *   , JFLOAT = 1
 *   , RM = 1
 *   , FUNCTION = USER(1000.0)
 *
 *   par[0] = spring stiffness k  (example: 1000 N/m)
 */

#include "slv_c_utils.h"

/* ------------------------------------------------------------------ */
/* Import the cached displacement written by CBKSUB                   */
/* ------------------------------------------------------------------ */
extern double cached_dy_marker5;

void vfosub_(int *id, double *time, double *par, int *npar,
             int *dflag, int *iflag, double *result)
{
    double k;
    double dy;
    int    errflg = 0;

    /* Stiffness taken from the first user parameter */
    k  = par[0];

    /* Read the cached displacement – no c_sysfnc call needed */
    dy = cached_dy_marker5;

    /*
     * Apply a simple spring force along the Y axis.
     * Modify the force law below to suit your model.
     *
     * result[0] = Fx
     * result[1] = Fy
     * result[2] = Fz
     */
    result[0] = 0.0;
    result[1] = -k * dy;
    result[2] = 0.0;

    (void)dflag;   /* unused in this example */
    (void)iflag;
    (void)errflg;
}
