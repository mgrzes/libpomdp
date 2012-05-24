package libpomdp.test;

import libpomdp.common.CustomMatrix;
import libpomdp.common.CustomVector;
import libpomdp.common.std.PomdpStd;
import libpomdp.parser.FileParser;
import libpomdp.solve.offline.Criteria;
import libpomdp.solve.offline.MaxIterationsCriteria;
import libpomdp.solve.offline.vi.ValueConvergenceCriteria;
import libpomdp.solve.offline.vi.ValueIterationStats;
import libpomdp.solve.offline.bounds.QmdpStd;

public class CassandraParserTest {

	/**
	 * @param args
	 * @throws Exception 
	 */
	public static void main(String[] args) throws Exception {
		System.out.println("current directory: " + System.getProperty("user.dir"));
		PomdpStd pomdp=(PomdpStd)FileParser.loadPomdp("/home/mgrzes/_data/Cassandra_POMDPs/modified/tiger.POMDP", FileParser.PARSE_CASSANDRA_POMDP);
		//PomdpStd pomdp=(PomdpStd)FileParser.loadPomdp("/home/mgrzes/_data/Cassandra_POMDPs/1d.POMDP", FileParser.PARSE_CASSANDRA_POMDP);

		System.out.println(pomdp.toString());

		for ( int i = 0 ; i < pomdp.nrActions(); i++ ) {
			CustomMatrix t = pomdp.getTransitionTable(i);
			System.out.println("Transition probabilities for action " + pomdp.getActionString(i) + "\n" + t.toString());
		}

		for ( int i = 0 ; i < pomdp.nrActions(); i++ ) {
			CustomMatrix o = pomdp.getObservationTable(i);
			System.out.println("Observation probabilities for action " + pomdp.getActionString(i) + "\n" + o.toString());
		}

		for ( int i = 0 ; i < pomdp.nrActions(); i++ ) {
			CustomVector r = pomdp.getRewardTable(i);
			System.out.println("R(s,a) rewards for action " + pomdp.getActionString(i) + "\n" + r.toString());
		}

	}

}
