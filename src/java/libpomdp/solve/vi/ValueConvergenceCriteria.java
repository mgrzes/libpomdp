package libpomdp.solve.vi;

import libpomdp.common.CustomVector;
import libpomdp.common.ValueFunction;
import libpomdp.solve.Criteria;
import libpomdp.solve.Iteration;

public class ValueConvergenceCriteria extends Criteria {

	double epsilon;
	int convCriteria;
	
	@Override
	public boolean check(Iteration i) {
		ValueIteration vi=(ValueIteration)i;
		ValueFunction newv=vi.getValueFunction();
		ValueFunction oldv=vi.getOldValueFunction();
		if (oldv==null)
			return false;
		switch(convCriteria){
			case CC_MAXEUCLID:
				if (newv.size()!=oldv.size())
					return false;
				double conv=0;
			   	for(int j=0; j<newv.size(); j++){
			   		CustomVector perf=newv.getVectorCopy(j);
			   		perf.add(-1.0,oldv.getVectorCopy(j));
			   		double a_value = perf.norm(2.0);	
					if (a_value > conv)
			   			conv=a_value;
			   	}
			   	System.out.println("Iteration " + i.getStats().iterations + ": " + conv);
			   	if (conv <= epsilon)
			   		return(true);
				break;
			default:
				System.out.println("Warning: Unknown Convergence Criteria");
				break;
		}
		return false;
	}

	@Override
	public boolean valid(Iteration vi) {
		if (vi instanceof ValueIteration){
			return true;
		}
		return false;
	}

	public ValueConvergenceCriteria(double epsilon,int convCriteria) {
		this.epsilon=epsilon;
		this.convCriteria=convCriteria;
	}
	


}
