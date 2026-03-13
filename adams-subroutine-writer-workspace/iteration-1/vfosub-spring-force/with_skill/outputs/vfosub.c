#include "slv_c_utils.h"

adams_c_Vfosub  Vfosub;   /* forward declaration — enables compiler type-checking */

/*
 * Vfosub — Linear spring VFORCE
 *
 * Applies:  Fx = -500 * (DX - 100)
 *           Fy = 0
 *           Fz = 0
 *
 * Moving marker (I):  10
 * Ground marker (J):  1
 * Force is expressed in the J-floating marker frame.
 *
 * USER parameters expected in the .adm:
 *   PAR[0] = stiffness  (500.0)
 *   PAR[1] = free length (100.0)
 *   PAR[2] = I marker   (10)
 *   PAR[3] = J marker   (1)
 */

void Vfosub( const struct sAdamsVforce *vfo, double time,
             int dflag, int iflag, double *result )
{
    /* Read USER parameters */
    double stiffness   = vfo->PAR[0];
    double free_length = vfo->PAR[1];
    int    marker_i    = (int) vfo->PAR[2];
    int    marker_j    = (int) vfo->PAR[3];

    /* SYSARY arguments */
    int    ipar[3];
    double disp[3];
    int    nstates;
    int    errflg;

    /* ---- iflag guard: skip non-evaluation passes ---- */
    if ( iflag == 5 || iflag == 7 || iflag == 9 )
        return;

    /* ---- Get translational displacement of I w.r.t. J, expressed in J ---- */
    ipar[0] = marker_i;   /* I marker  */
    ipar[1] = marker_j;   /* J marker  */
    ipar[2] = marker_j;   /* express results in J frame */

    c_sysary( "TDISP", ipar, 3, disp, &nstates, &errflg );
    c_errmes( errflg, "SYSARY TDISP failed in Vfosub", vfo->ID, "STOP" );

    /* ---- Compute spring force: Fx = -k * (DX - free_length) ---- */
    result[0] = -stiffness * ( disp[0] - free_length );
    result[1] = 0.0;
    result[2] = 0.0;
}
