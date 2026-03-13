/**
 * VFOSUB - User subroutine for Adams VFORCE element.
 * Applies a linear spring force: Fx = -500 * (DX - 100)
 * Moving marker: 10, Ground marker: 1
 */

#include <stdio.h>
#include <string.h>
#include "slv_c_utils.h"

void vfosub_(int *id, double *time, double *par, int *npar,
             int *dflag, int *iflag, double *result)
{
    int errflg = 0;
    double dx;
    int ipar[3];
    int nargs;
    char func_name[4];

    /* Initialize all force/torque components to zero */
    result[0] = 0.0;  /* Fx */
    result[1] = 0.0;  /* Fy */
    result[2] = 0.0;  /* Fz */
    result[3] = 0.0;  /* Tx */
    result[4] = 0.0;  /* Ty */
    result[5] = 0.0;  /* Tz */

    /* If iflag is set, return zero values for initialization */
    if (*iflag != 0) {
        return;
    }

    /* Evaluate DX(10, 1) - displacement of marker 10 w.r.t. marker 1 */
    strcpy(func_name, "DX");
    ipar[0] = 10;   /* moving marker */
    ipar[1] = 1;    /* ground marker */
    nargs = 2;

    c_sysfnc(func_name, ipar, nargs, &dx, &errflg);

    if (errflg != 0) {
        c_errmes(1, "Error in VFOSUB: could not evaluate DX", *id, "VFORCE");
        return;
    }

    /* Compute spring force: Fx = -500 * (DX - 100) */
    result[0] = -500.0 * (dx - 100.0);
}
