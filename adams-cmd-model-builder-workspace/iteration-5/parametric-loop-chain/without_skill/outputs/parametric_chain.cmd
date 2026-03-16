! ===========================================================
! parametric_chain.cmd
!
! Creates a chain of 8 point masses in a straight line along
! the X axis, spaced 50 mm apart, starting at the origin.
!
!   - Mass 1 is fixed to ground with a FIXED joint.
!   - Consecutive masses are connected by spring-dampers:
!       K = 100 N/mm,  C = 1.0 N*s/mm,  free length = 50 mm
!   - Each mass = 0.25 kg
!   - Parametric construction: FOR loop + EVAL + RTOI + //
!   - Simulation duration: 2.0 seconds
!
! Unit system: mm, kg, N, s
!
! Entity ID scheme:
!   Parts               N          1 .. 8
!   CM markers          10*N       10, 20, 30, ..., 80
!   Connection markers  10*N + 1   11, 21, 31, ..., 81
!   Ground marker       901
!   Fixed-joint marker  902  (on Part 1)
!   Fixed joint         1
!   Spring-dampers      100 + N    101, 102, ..., 107
! ===========================================================

MODEL/MODEL_NAME = parametric_chain

! -----------------------------------------------------------
! SECTION 1 — Create 8 point masses using a FOR loop
!
!   EVAL(expr)  evaluates an arithmetic expression to produce
!               a numeric entity ID or parameter value.
!   RTOI(real)  converts a real-valued variable to an integer,
!               required for clean ID arithmetic and string
!               construction when the loop variable is REAL.
!   //          string-concatenation operator used to build
!               entity LABEL fields.
! -----------------------------------------------------------

FOR/VARIABLE = N, START = 1, END = 8, INC = 1

  ! Create part N (point mass) with 0.25 kg and minimal inertia
  PART/EVAL(RTOI(N)), &
      MASS  = 0.25, &
      IP    = 1.0E-6, 1.0E-6, 1.0E-6, &
      LABEL = "MASS_" // RTOI(N)

  ! CM marker in the ground frame at X = (N-1)*50 mm
  MARKER/EVAL(RTOI(N)*10), &
      PART = EVAL(RTOI(N)), &
      QP   = EVAL((RTOI(N)-1)*50.0), 0.0, 0.0

  ! Assign the CM marker to the part
  PART/EVAL(RTOI(N)), CM = EVAL(RTOI(N)*10)

  ! Connection marker at the same location (spring attachment point)
  MARKER/EVAL(RTOI(N)*10+1), &
      PART = EVAL(RTOI(N)), &
      QP   = EVAL((RTOI(N)-1)*50.0), 0.0, 0.0

END_FOR

! -----------------------------------------------------------
! SECTION 2 — Fix Mass 1 to ground at the origin
!
!   Marker 901 : fixed to the ground part (PART=0) at origin
!   Marker 902 : on Part 1 at origin
!   Joint 1    : FIXED joint anchoring Mass 1
! -----------------------------------------------------------

MARKER/901, PART = 0, QP = 0.0, 0.0, 0.0
MARKER/902, PART = 1, QP = 0.0, 0.0, 0.0
JOINT/1, FIXED, I = 902, J = 901

! -----------------------------------------------------------
! SECTION 3 — Spring-dampers between consecutive masses
!
! Spring (100+N) connects Mass N to Mass N+1:
!   I marker = 10*N + 1   (connection marker on Mass N)
!   J marker = 10*N + 11  (connection marker on Mass N+1,
!              because 10*(N+1)+1 = 10*N+11)
!
! Free length 50 mm equals the initial spacing, so the chain
! starts at static equilibrium.
! -----------------------------------------------------------

FOR/VARIABLE = N, START = 1, END = 7, INC = 1

  SPRING/EVAL(RTOI(N)+100), &
      I      = EVAL(RTOI(N)*10+1), &
      J      = EVAL(RTOI(N)*10+11), &
      K      = 100.0, &
      C      = 1.0, &
      LENGTH = 50.0, &
      LABEL  = "SPRING_" // RTOI(N) // "_" // RTOI(N+1)

END_FOR

! -----------------------------------------------------------
! SECTION 4 — Transient simulation: 2.0 seconds
!   DTOUT = 0.01 s  →  200 output frames
! -----------------------------------------------------------

SIMULATE/TRANSIENT, END = 2.0, DTOUT = 0.01
