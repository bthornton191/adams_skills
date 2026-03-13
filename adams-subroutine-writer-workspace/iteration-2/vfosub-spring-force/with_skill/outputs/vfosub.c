#include "slv_c_utils.h"

adams_c_Vfosub    Vfosub;

/*
 * VFOSUB — Linear spring force in X direction.
 *
 *   Fx = -K * (DX - free_length)
 *   Fy = 0
 *   Fz = 0
 *
 * USER() parameters:
 *   PAR[0] = K            (spring stiffness)
 *   PAR[1] = free_length  (spring free / natural length)
 *
 * Markers:
 *   I      = moving marker (action point)
 *   JFLOAT = ground / reference marker (reaction point)
 *   RM     = result marker (frame for force components)
 */

void Vfosub(const struct sAdamsVforce *vfo, double time,
            int dflag, int iflag, double *result)
{
    /* Read USER() parameters */
    double K        = vfo->PAR[0];
    double free_len = vfo->PAR[1];

    int    ipar[3]  = { vfo->I, vfo->JFLOAT, vfo->JFLOAT };
    double disp[3];
    int    nstates;
    int    errflg;

    /* Skip non-evaluation passes (serialization, etc.) */
    if (iflag == 5 || iflag == 7 || iflag == 9)
        return;

    /* Get translational displacement of I relative to JFLOAT,
       resolved in the JFLOAT frame */
    c_sysary("TDISP", ipar, 3, disp, &nstates, &errflg);
    c_errmes(errflg, "c_sysary TDISP failed in Vfosub", vfo->ID, "STOP");

    /* Linear spring: Fx = -K * (DX - free_length) */
    result[0] = -K * (disp[0] - free_len);
    result[1] = 0.0;
    result[2] = 0.0;
}
