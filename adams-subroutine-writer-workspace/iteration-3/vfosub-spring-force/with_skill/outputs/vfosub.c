#include "slv_c_utils.h"

adams_c_Vfosub    Vfosub;

/*
 * VFOSUB — Linear spring force acting in the X direction.
 *
 *   Fx = -K * (DX - free_length)
 *   Fy = 0
 *   Fz = 0
 *
 * USER() parameters (PAR array, 0-indexed in C):
 *   PAR[0] = K            — spring stiffness (e.g. 500)
 *   PAR[1] = free_length  — spring natural length (e.g. 100)
 *
 * VFORCE markers (set in the .adm model):
 *   I      = moving marker  (action point,   marker 10)
 *   JFLOAT = ground marker  (reaction point, marker  1)
 *   RM     = result marker  (force frame,    typically = JFLOAT)
 */
void Vfosub(const struct sAdamsVforce *vfo, double time,
            int dflag, int iflag, double *result)
{
    double K        = vfo->PAR[0];
    double free_len = vfo->PAR[1];

    /* TDISP ipar: [marker_i, marker_j, marker_k]
       marker_k = JFLOAT resolves displacement in the ground frame */
    int    ipar[3] = { vfo->I, vfo->JFLOAT, vfo->JFLOAT };
    double disp[3];
    int    nstates;
    int    errflg;

    /* Skip serialization / expression-destruction passes.
       Calls are still made for iflag 0, 1, and 3 so the
       Jacobian sparsity pattern is correctly registered.    */
    if (iflag == 5 || iflag == 7 || iflag == 9)
        return;

    /* Translational displacement of I relative to JFLOAT,
       expressed in the JFLOAT frame.
       disp[0] = DX, disp[1] = DY, disp[2] = DZ             */
    c_sysary("TDISP", ipar, 3, disp, &nstates, &errflg);
    c_errmes(errflg, "c_sysary TDISP failed in Vfosub", vfo->ID, "STOP");

    /* Linear spring: Fx = -K * (DX - free_length) */
    result[0] = -K * (disp[0] - free_len);
    result[1] = 0.0;
    result[2] = 0.0;
}
