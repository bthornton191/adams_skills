/**
 * vfosub.c
 *
 * Adams VFOSUB vector-force subroutine.
 * Reads the cached Y displacement from CBKSUB instead of
 * calling c_sysfnc("DY", ...) on every force evaluation.
 *
 * par[0] = stiffness (N/mm or model units)
 */

#include "slv_c_utils.h"

/* Import the cached displacement from cbksub.c */
extern double get_cached_dy(void);

void vfosub(int *id, double *time, double *par, int *npar,
            int *dflag, int *iflag, double *result)
{
    double dy;
    double stiffness;

    /* Grab the value that CBKSUB already computed this iteration */
    dy = get_cached_dy();

    /* Stiffness passed in as the first user parameter */
    stiffness = par[0];

    /* Restoring spring force along Y only */
    result[0] =  0.0;                /* Fx */
    result[1] = -stiffness * dy;     /* Fy */
    result[2] =  0.0;                /* Fz */

    *iflag = 0;
}
