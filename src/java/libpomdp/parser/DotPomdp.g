/** ------------------------------------------------------------------------- *
 * libpomdp
 * ========
 * File: DotPomdp.g
 * Description: ANTLRv3 grammar specification to parse a .POMDP file in
 *              Cassandra's format. Not all features are supported yet.
 *              Sparse matrices and arrays use the MTJ matrix package.
 * Copyright (c) 2009, 2010 Diego Maniloff 
 * W3: http://www.cs.uic.edu/~dmanilof
 --------------------------------------------------------------------------- */

grammar DotPomdp;


/*------------------------------------------------------------------
 * TOKENS
 *------------------------------------------------------------------*/
tokens {
    DISCOUNTTOK     = 'discount' ;
    VALUESTOK       = 'values' ;
    STATESTOK       = 'states' ;
    ACTIONSTOK      = 'actions' ;
    OBSERVATIONSTOK = 'observations' ;
    TTOK            = 'T' ;
    OTOK            = 'O' ;
    RTOK            = 'R' ;
    UNIFORMTOK      = 'uniform' ;
    IDENTITYTOK     = 'identity' ;
    REWARDTOK       = 'reward' ;
    REWARDSTOK      = 'rewards' ;
    COSTTOK         = 'cost' ;
    STARTTOK        = 'start' ;
    INCLUDETOK      = 'include' ; 
    EXCLUDETOK      = 'exclude' ;
    RESETTOK        = 'reset' ;
    COLONTOK        = ':' ;
    ASTERICKTOK     = '*' ;
    PLUSTOK         = '+' ;
    MINUSTOK        = '-' ;
}

/*------------------------------------------------------------------
 * LEXER INITIALIZATIONS
 *------------------------------------------------------------------*/
@lexer::header {
    package libpomdp.parser;
}

/*------------------------------------------------------------------
 * PARSER INITIALIZATIONS
 *------------------------------------------------------------------*/
@header {
    package libpomdp.parser;
    import libpomdp.common.CustomVector;
    import libpomdp.common.CustomMatrix;  
  
}

@members {
    // main method
    public static void main(String[] args) throws Exception {
        DotPomdpLexer lex = new DotPomdpLexer(new ANTLRFileStream(args[0]));
       	CommonTokenStream tokens = new CommonTokenStream(lex);
        DotPomdpParser parser = new DotPomdpParser(tokens);

        try {
            parser.dotPomdp();
        } catch (RecognitionException e)  {
            e.printStackTrace();
        }
    }

	
	private int matrixContext;
	
	private static final int MC_TRANSITION = 0;
	private static final int MC_TRANSITION_ROW = 1;
	private static final int MC_OBSERVATION = 2;
	private static final int MC_OBSERVATION_ROW = 3;
    // main structure
    private PomdpSpecStd dotPomdpSpec = new PomdpSpecStd();

    // threshold for sums of distros
    final double THRESHOLD = 1e-5;

    // return main structure
    public PomdpSpecStd getSpec() {
        return dotPomdpSpec;
    }

    // simple debug mesg
    private void err(String msg) {
        System.err.println(msg);
    }
}

/*------------------------------------------------------------------
 * LEXER RULES
 *------------------------------------------------------------------*/
STRING  
    :   ('a'..'z'|'A'..'Z') ('a'..'z'|'A'..'Z'|'0'..'9'|'_'|'-')*
    ;

INT     
    :   '0' | ('1'..'9') ('0'..'9')*
    ;

FLOAT
    :   ('0'..'9')+ '.' ('0'..'9')* EXPONENT?
    |   '.' ('0'..'9')+ EXPONENT?
    |   ('0'..'9')+ EXPONENT
    ;

COMMENT
    :   '#' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    |   '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    |   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;} // can also use skip()?
    ;

WS  
    :   ( ' '
    |   '\t'
    |   '\r'
    |   '\n'
        ) {$channel=HIDDEN;}
    ;


fragment
EXPONENT : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/
dotPomdp
    :
        {
      		System.out.println("PARSER: Parsing preamble...");
        }            
      preamble
        {
            /* print out summary info from the preamble */
        	System.out.println("PARSER: Summary -> states "+dotPomdpSpec.nrSta);
        	System.out.println("                -> observations "+dotPomdpSpec.nrObs);
        	System.out.println("                -> actions "+dotPomdpSpec.nrAct);
            
            // we can now initialize the data structures for T, O, R
            /* initialize |A| s x s' matrices
               T: <action> : <start-state> : <end-state> prob  */
            dotPomdpSpec.T = new CustomMatrix[dotPomdpSpec.nrAct];
            for(int a=0; a<dotPomdpSpec.nrAct; a++) 
                dotPomdpSpec.T[a] = new CustomMatrix(dotPomdpSpec.nrSta,
                                                    dotPomdpSpec.nrSta);
            /* initialize |A| s' x o matrices
               O : <action> : <end-state> : <observation> prob */        
            dotPomdpSpec.O = new CustomMatrix[dotPomdpSpec.nrAct];
            for(int a=0; a<dotPomdpSpec.nrAct; a++) 
                dotPomdpSpec.O[a] = new CustomMatrix(dotPomdpSpec.nrSta,
                                                    dotPomdpSpec.nrObs);
               System.out.println("PARSER: Parsing starting state/belief...");
        }
      start_state 
        {
            // make sure the start state is a distribution
            
            //System.out.println("Successfully parsed start state");
            if (dotPomdpSpec.startState.norm(1.0) - 1.0 > THRESHOLD)
                err("Start state not a distribution" + dotPomdpSpec.startState.norm(1));
            System.out.println("PARSER: Parsing parameters...");
        }
      param_list 
        {
            // there should be a check for the parameter distros here...

            if ( dotPomdpSpec.partialR != null && dotPomdpSpec.fullR != null ) {
                System.err.println("R(a,s,s') and R(a,s,s',o) rewards cannot be used together");
                System.exit(1);
            }

            /* reward compression: this is the right approach because it unifies rewards to R(s,a)
               and planners do not have to cope with different types of rewards. */
            double value;
            if ( dotPomdpSpec.partialR != null ) {
                /* R(s,a) = \sum_sp R(s,a,s') T(s,a,s') */
                System.out.println("PARSER: Compressing R(s,a,s') rewards...");
                if ( dotPomdpSpec.R == null) {
                    dotPomdpSpec.R = new CustomVector[dotPomdpSpec.nrAct];
                    for(int a=0; a<dotPomdpSpec.nrAct; a++)
                    dotPomdpSpec.R[a] = new CustomVector(dotPomdpSpec.nrSta);
                } else {
                    System.err.println("R(a,s) and R(a,s,s') rewards cannot be used together");
                    System.exit(1);
                }
                for (int a=0;a<dotPomdpSpec.nrAct;a++) {
                    for (int s=0;s<dotPomdpSpec.nrSta;s++) {

                        value = 0;
                        for (int sp=0;sp<dotPomdpSpec.nrSta;sp++) { // would need a getRow() to avoid this, this dot prod is VERY slow
                            value += dotPomdpSpec.partialR[a].get(s, sp) * dotPomdpSpec.T[a].get(s, sp);
                        }
                        if ( value != dotPomdpSpec.R[a].get(s) ) {
                            dotPomdpSpec.R[a].set(s, value);
                        }
                    }
                }
            }
            if ( dotPomdpSpec.fullR != null ) {
                System.err.println("PARSER: Compressing R(s,a,s',o') rewards...");
                // TODO: the block below seems to be the only place that needs to be fixed in order to use full rewards!
                // R(s,a) = \sum_s' [ \sum_o' R(s,a,s',o')O(a,s',o') ] T(s,a,s')
                if ( dotPomdpSpec.R == null) {
                    dotPomdpSpec.R = new CustomVector[dotPomdpSpec.nrAct];
                    for(int a=0; a<dotPomdpSpec.nrAct; a++)
                    dotPomdpSpec.R[a] = new CustomVector(dotPomdpSpec.nrSta);
                } else {
                     System.err.println("R(a,s) and R(a,s,s',o) rewards cannot be used together");
                     System.exit(1);
                }
                for (int a=0;a<dotPomdpSpec.nrAct;a++){
                    for (int s=0;s<dotPomdpSpec.nrSta;s++){
                        CustomMatrix prod=dotPomdpSpec.O[a].transBmult(dotPomdpSpec.fullR[a][s]);

                        System.out.println("O["+a+"]\n" + dotPomdpSpec.O[a].toString());
                        // TODO: The parser does not get R(s,a,s',o') right at the moment ...
                        System.out.println("R["+a+"]["+s+"]\n" + dotPomdpSpec.fullR[a][s].toString());
                        System.out.println("Product:\n" + prod.toString());

                        value = 0;
                        for (int sp=0;sp<dotPomdpSpec.nrSta;sp++){
                            value+=prod.get(sp,sp) * dotPomdpSpec.T[a].get(s, sp); // TODO: bug here?
                        }
                        dotPomdpSpec.R[a].set(s,value);
                    }
                }
                System.err.println("rewards R(s,a,s',o) are not properly implemented");
                System.exit(1);
            }

            System.out.println("PARSER: [DONE]");
        }
    ;

preamble        
    : param_type*        
    ;

param_type      
    : discount_param
    | value_param
    | state_param
    | action_param
    | obs_param
    ;


discount_param  // set discount factor in global problem struct
    : DISCOUNTTOK COLONTOK FLOAT {
        dotPomdpSpec.discount = Double.parseDouble($FLOAT.text);
    }
    | DISCOUNTTOK COLONTOK INT {
        dotPomdpSpec.discount = Double.parseDouble($INT.text);
    }
    ;

value_param     
    : VALUESTOK COLONTOK value_tail
    ;

value_tail      
    : REWARDTOK
    | REWARDSTOK
    | COSTTOK
         {err("PARSER: Costs are not supported... sure that you want to use costs?");}
    ;

state_param     
    : STATESTOK COLONTOK state_tail
    ;

state_tail      
    : INT
        // we only get the total # of states
        {dotPomdpSpec.nrSta   = Integer.parseInt($INT.text);}
    | ident_list
        // we get a list of states, convert to array
        {dotPomdpSpec.staList = $ident_list.list;
         dotPomdpSpec.nrSta   = dotPomdpSpec.staList.size();}
    ;

action_param     
    : ACTIONSTOK COLONTOK action_tail
    ;

action_tail      
    : INT
        // we only get the total # of actions
        {dotPomdpSpec.nrAct   = Integer.parseInt($INT.text);}
    | ident_list
        // we get a list of actions
        {dotPomdpSpec.actList = $ident_list.list;
         dotPomdpSpec.nrAct   = dotPomdpSpec.actList.size();}
    ;

obs_param 
    : OBSERVATIONSTOK COLONTOK obs_param_tail
    ;

obs_param_tail 
    : INT
        // we only get the total # of observations
        {dotPomdpSpec.nrObs   = Integer.parseInt($INT.text);}
    | ident_list
        // we get a list of observations
        {dotPomdpSpec.obsList = $ident_list.list;
         dotPomdpSpec.nrObs   = dotPomdpSpec.obsList.size();}
    ;

start_state     
    : STARTTOK COLONTOK prob_vector
        // we'll focus on this case for now, just a sparse vector
        {
            //System.out.println("ENTERED the first case for start state");
            dotPomdpSpec.startState = $prob_vector.vector;
        }
    | STARTTOK COLONTOK STRING
        {err("PARSER: MDPs are not supported yet, only POMDPs");}
    | STARTTOK INCLUDETOK COLONTOK start_state_list
         {err("PARSER: Include and exclude features are not supported yet");}
    | STARTTOK EXCLUDETOK COLONTOK start_state_list
         {err("PARSER: Include and exclude features are not supported yet");}
    |  /* empty */
    	{
    	// Empty start state means uniform belief
    	dotPomdpSpec.startState=new CustomVector(CustomVector.getUniform(dotPomdpSpec.nrSta));
    	}
    ;

start_state_list    
    : state+
    ;

param_list     
    : param_spec*
    ;

param_spec     
    : trans_prob_spec
    | obs_prob_spec 
    | reward_spec
    ;

trans_prob_spec     
    : TTOK COLONTOK trans_spec_tail
    ;

trans_spec_tail     
    : paction COLONTOK s_1=state COLONTOK s_2=state prob // this would not detect probs>1
        // triple loop with lists
        {
            // if($prob.p > 0.0) //Some files relies in rewriting... bad thing... 
                for(int a : $paction.l)
                    for(int s1 : $s_1.l)
                        for(int s2 : $s_2.l)
                            dotPomdpSpec.T[a].set(s1, s2, $prob.p);
        }
    | paction {matrixContext=MC_TRANSITION_ROW;} COLONTOK state u_matrix
        {
        	for(int a : $paction.l)	
        		for (int s : $state.l)
        			for (int i=0;i<dotPomdpSpec.nrSta;i++)
        				dotPomdpSpec.T[a].set(s,i,$u_matrix.m.get(i,0));
        }
    | paction {matrixContext=MC_TRANSITION;} ui_matrix
        // full matrix specification, set if for each action 
        {
            for(int a : $paction.l) dotPomdpSpec.T[a] = $ui_matrix.m.copy();
        }
    ;

obs_prob_spec  
    : OTOK COLONTOK obs_spec_tail
    ;

obs_spec_tail  
    : paction COLONTOK state COLONTOK obs prob
        // triple loop with lists
        {
        //if($prob.p > 0.0) // rewriting... puff 
            for(int a : $paction.l)
                for(int s2 : $state.l)
                    for(int o : $obs.l)
                        dotPomdpSpec.O[a].set(s2, o, $prob.p);
        }
    | paction {matrixContext=MC_OBSERVATION_ROW;} COLONTOK state u_matrix
        {
        	for(int a : $paction.l)	
        		for (int s : $state.l)
        			for (int i=0;i<dotPomdpSpec.nrObs;i++)
        				dotPomdpSpec.O[a].set(s,i,$u_matrix.m.get(i,0));
        }
    | paction {matrixContext=MC_OBSERVATION;} u_matrix
        // full matrix specification, set if for each action 
        {
        	for(int a : $paction.l) {
        	    // create a copy of a matrix in case one action will have different values defined below in the file
        	    dotPomdpSpec.O[a] = $u_matrix.m.copy();
        	}
        }
    ;

reward_spec    
    : RTOK COLONTOK reward_spec_tail
    ;

reward_spec_tail 
    : paction COLONTOK s_1=state COLONTOK s_2=state COLONTOK obs number
        {
            if ( $obs.text.equals(Character.toString('*')) ) {
                if ( $s_2.text.equals(Character.toString('*')) ) {
                    // R(a,s) where a and/or s can be '*'
                    if ( dotPomdpSpec.R == null) {
                        System.out.println("PARSER: R(s,a) reward representation detected.");
                        dotPomdpSpec.R = new CustomVector[dotPomdpSpec.nrAct];
                        for(int a=0; a<dotPomdpSpec.nrAct; a++)
                        dotPomdpSpec.R[a] = new CustomVector(dotPomdpSpec.nrSta);
                    }
                    for(int a : $paction.l)
                        for(int s1 : $s_1.l) {
                            double curr = dotPomdpSpec.R[a].get(s1);
                            if ( curr != $number.n ) {
                                dotPomdpSpec.R[a].set(s1, $number.n);
                            }
                        }
                } else {
                    // R(a,s,s')
                    if ( dotPomdpSpec.partialR == null ) {
                        System.out.println("PARSER: R(s,a,s') reward representation detected.");
                        // create |A| matrices
                        dotPomdpSpec.partialR = new CustomMatrix[dotPomdpSpec.nrAct];
                        for(int a=0; a<dotPomdpSpec.nrAct; a++) {
                            dotPomdpSpec.partialR[a] = new CustomMatrix(dotPomdpSpec.nrSta, dotPomdpSpec.nrSta);
                        }
                    }
                    for(int a : $paction.l)
                        for(int s1 : $s_1.l)
                            for(int s2 : $s_2.l) {
                                double curr = dotPomdpSpec.partialR[a].get(s1, s2);
                                if ( curr != $number.n ) {
                                    dotPomdpSpec.partialR[a].set(s1, s2, $number.n);
                                }
                            }
                }
            } else {
                // R(a,s,s',o)
                if ( dotPomdpSpec.fullR == null ) {
                    System.out.println("PARSER: R(s,a,s',o') reward representation detected, you'll probably run out of memory.");
                    // Creating Huge Reward Matrix (4D)
                    dotPomdpSpec.fullR = new CustomMatrix[dotPomdpSpec.nrAct][dotPomdpSpec.nrSta];
                    for(int a=0; a<dotPomdpSpec.nrAct; a++)
                        for(int s=0; s<dotPomdpSpec.nrSta; s++){
                            dotPomdpSpec.fullR[a][s] = new CustomMatrix(dotPomdpSpec.nrSta,dotPomdpSpec.nrObs);
                        }
                }
                for(int a : $paction.l)
                    for(int s1 : $s_1.l)
                        for(int s2 : $s_2.l)
                            for(int o : $obs.l) {
                                double curr = dotPomdpSpec.fullR[a][s1].get(s2, o);
                                if ( curr != $number.n ) {
                                    dotPomdpSpec.fullR[a][s1].set(s2, o, $number.n);
                                }
                            }
            }
        }
    | paction COLONTOK state COLONTOK state num_matrix
        {
        err("unsupported feature COLONTOK state COLONTOK state num_matrix");}
    | paction COLONTOK state num_matrix
        {err("unsupported feature COLONTOK state num_matrix");}
    ;

ui_matrix returns [CustomMatrix m]     
    : UNIFORMTOK 
    	{$m = CustomMatrix.getUniform(dotPomdpSpec.nrSta,dotPomdpSpec.nrSta);}
    | IDENTITYTOK 
        {$m = CustomMatrix.getIdentity(dotPomdpSpec.nrSta);}
    | prob_matrix
    	{$m = $prob_matrix.m;}
    ;

u_matrix returns [CustomMatrix m]
    : UNIFORMTOK
    	{
    	switch (matrixContext){
    	case MC_OBSERVATION: 
    		$m = CustomMatrix.getUniform(dotPomdpSpec.nrSta,dotPomdpSpec.nrObs);
    		break;
    	case MC_TRANSITION:
    		$m = CustomMatrix.getUniform(dotPomdpSpec.nrSta,dotPomdpSpec.nrSta);
    		break;
    	case MC_TRANSITION_ROW:
    		$m = CustomMatrix.getUniform(1,dotPomdpSpec.nrSta);
    		break;
 		case MC_OBSERVATION_ROW:
    		$m = CustomMatrix.getUniform(1,dotPomdpSpec.nrObs);
    		break;
    	default:
    		err("PARSER: wrong matrix context... umh? (UNIFORMTOK)");
    		break;
    	}
    	}
    | RESETTOK
    	{err("PARSER: the reset feature is not supported yet");}
    | prob_matrix
    	{$m = $prob_matrix.m;}
    ;

prob_matrix returns [CustomMatrix m]
    : 
     {
     int index = 0;
     int i_max,j_max;
     	switch (matrixContext){
    	case MC_OBSERVATION:
    	 	i_max = dotPomdpSpec.nrSta;
    	 	j_max = dotPomdpSpec.nrObs;
   			break;
    	case MC_TRANSITION:
    	 	i_max = dotPomdpSpec.nrSta;
    	 	j_max = dotPomdpSpec.nrSta;
    		break;
    	case MC_TRANSITION_ROW:
    	 	i_max = dotPomdpSpec.nrSta;
    	 	j_max = 1;
    		break;
 		case MC_OBSERVATION_ROW:
 		    i_max = dotPomdpSpec.nrObs;
    	 	j_max = 1;
    		break;
    	default:
    		err("PARSER: wrong matrix context... umh? (prob_matrix)");
    		j_max=0;
    		i_max=0;
    		break;
    	}  
     $m = new CustomMatrix(i_max,j_max);
     } 
        (prob 
        {
        	if ($prob.p > 0.0) $m.set(index / j_max, index \% j_max, $prob.p);
            index++;
        }
        )+
    ;

prob_vector returns [CustomVector vector]
    : 
        // initialization here is OK
        {int index = 0; $vector = new CustomVector(dotPomdpSpec.nrSta);} 
        (prob 
        {
            // action here - the check for 0 actually doesn't matter
            if ($prob.p > 0.0) $vector.set(index, $prob.p);
            index++;
        }
        )+
    ;

num_matrix     
    :      {
     int index = 0;
     //int i_max;
     } 
        (number 
        {
            index++;
        }
        )+
    ;

state returns [ArrayList<Integer> l = new ArrayList<Integer>()]
    :
        INT 
        {$l.add(Integer.parseInt($INT.text));}
    | 
        STRING
        {$l.add(dotPomdpSpec.staList.indexOf($STRING.text));}
    | 
        ASTERICKTOK
        {for(int s=0; s<dotPomdpSpec.nrSta; s++) $l.add(s);}
    ;   

paction returns [ArrayList<Integer> l = new ArrayList<Integer>()]
    :
        INT 
        {$l.add(Integer.parseInt($INT.text));}
    | 
        STRING
        {$l.add(dotPomdpSpec.actList.indexOf($STRING.text));}
    | 
        ASTERICKTOK
        {for(int a=0; a<dotPomdpSpec.nrAct; a++) $l.add(a);}
    ;

obs returns [ArrayList<Integer> l = new ArrayList<Integer>()]    
    :
        INT 
        {$l.add(Integer.parseInt($INT.text));}
    | 
        STRING
        {$l.add(dotPomdpSpec.obsList.indexOf($STRING.text));}
    | 
        ASTERICKTOK
        {for(int o=0; o<dotPomdpSpec.nrObs; o++) $l.add(o);}
    ;

ident_list returns [ArrayList<String> list]     
    : 
        {$list = new ArrayList<String>();}
        (STRING
        {$list.add($STRING.text);}
        )+
    ;

prob returns [double p]      
    : INT
        {$p = Double.parseDouble($INT.text);}
    | FLOAT
        {$p = Double.parseDouble($FLOAT.text);}  
    ;

number returns [double n]          
    : optional_sign INT
        {$n = $optional_sign.s * Double.parseDouble($INT.text);} 
    | optional_sign FLOAT
        {$n = $optional_sign.s * Double.parseDouble($FLOAT.text);} 
    ;

optional_sign returns [int s]
    : PLUSTOK
        {$s = 1;}
    | MINUSTOK
        {$s = -1;}
    |  /* empty */
        {$s = 1;}
    ;
