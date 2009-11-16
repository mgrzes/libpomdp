/** ------------------------------------------------------------------------- *
 * libpomdp
 * ========
 * File: pomdp.java
 * Description: interface to represent pomdp problem specifications
 * Copyright (c) 2009, Diego Maniloff 
 * W3: http://www.cs.uic.edu/~dmanilof
 --------------------------------------------------------------------------- */

interface pomdp {

    /// P(o|b,a) in vector form for all o's
    // does not seem to be necessary anymore since we
    // are reusing computation from tao(b,a,o)
    //public double[] P_Oba(belState b, int a);

    /// tao(b,a,o)
    public belState tao(belState b, int a, int o);

    /// R(b,a)
    public double Rba(belState b, int a);

    /// T(s,a,s'): s x s' matrix
    /// will generally be used by mdp.java
    public double[][] getT(int a);

    /// R(s,a): 1 x s vector
    public double[] getR(int a);

    /// nrSta: total # of states
    public int getnrSta();

    /// nrAct: # of actions
    public int getnrAct();

    /// nrObs: total # of observations
    public int getnrObs();

    /// \gamma
    public double getGamma();

    /// initial belief state
    public belState getInit();

    /// action names
    public String getactStr(int a);

    /// observation names
    public String getobsStr(int o);

} // pomdp