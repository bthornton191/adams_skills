/*
 * VFOSUB - Adams VFORCE User Subroutine
 * Applies a linear spring force: Fx = -500 * (DX(10,1) - 100)
 *
 * Moving marker: 10
 * Ground marker: 1
 */

#include "slv_c_utils.h"

#ifdef _WIN32
#define DLLFUNC __declspec(dllexport)
#else
#define DLLFUNC
#endif

DLLFUNC void vfosub_(
    int    *id,
    double *time,
    double *par,
    int    *npar,
    int    *dflag,
    int    *iflag,
    double *result)
{
    double dx;
    int    ipar[2];
    int    nipar = 2;
    int    errflg = 0;

    /*
     * Evaluate DX(10, 1):
     * Translational x-displacement of marker 10 w.r.t. marker 1
     */
    ipar[0] = 10;  /* moving marker  */
    ipar[1] = 1;   /* reference marker (ground) */

    c_sysfnc("DX", ipar, nipar, &dx, &errflg);

    if (errflg != 0)
    {
        c_errmes(1, "VFOSUB: failed to evaluate DX(10,1)", *id, "VFORCE");
        return;
    }

    /* Linear spring: Fx = -500 * (DX - 100) */
    result[0] = -500.0 * (dx - 100.0);   /* Fx */
    result[1] = 0.0;                       /* Fy */
    result[2] = 0.0;                       /* Fz */
    result[3] = 0.0;                       /* Tx */
    result[4] = 0.0;                       /* Ty */
    result[5] = 0.0;                       /* Tz */
}
