TODO: rewards are fine overall in the current version of the flat (Cassandra's format) parser, but currently only one
type of the reward is allowed per one pomdp file. I need to changed this so that at least every action in one file could
have a different reward specification.

mglibpomdp
--------

mglibpomdp is a fork of the libpomdp library modified and extended by
Marek Grzes.

libpomdp (or libPOMDP) is an implementation of different offline and
online Partially Observable Markov Decision Process (POMDP)
approximation algorithms. The code is a combination of Java,
Matlab, and some Jython.

libpomdp has different dependencies, according to what algorithm you
want to run:

- the Matlab implementation of [1], 
- the Symbolic Perseus Package [5],
- matrix-toolkits-java [9].

libpomdp was started by Diego Maniloff at the University of Illinois
at Chicago and is now being jointly developed with Mauricio Araya from
INRIA at Nancy. We always welcome POMDP researchers to fork the
project and help us out.

Copyright (c) 2009, 2010, 2011 Diego Maniloff.  
Copyright (c) 2010, 2011 Mauricio Araya.


Contents
--------

- Directories and files
- Implemented algorithms
- Documentation
- References

Directories and files
---------------------

README		       - this file
external/    	       - dependencies
src/libpomdp/common/   - general POMDP interfaces 
src/libpomdp/hybrid/   - implementation of hybrid POMDP algorithms
src/libpomdp/offline/  - implementation of offline POMDP algorithms
src/libpomdp/online/   - implementation of online POMDP algorithms
src/libpomdp/problems/ - POMDP problems 

Implemented algorithms
----------------------
On its way.

Documentation
-------------
On its way.

Compilation
------------

1) obtain required libraries and put them in $HOME/lib, for example
2) then link that directory to external in the libpomdp directory:
   cd libpomdp
   ln -s $HOME/lib external
3) ant parser # build the parser;
4) ant compile # compile the project using ant

Compilation using InteliJ
1) after building the parser, InteliJ should compile the whole thing but first all required jar files have
   to be added to the project file in InteliJ

Some References (growing list)
------------------------------
[1] Spaan, M. T.J, and N. Vlassis. "Perseus: Randomized point-based
value iteration for POMDPs." Journal of Artificial Intelligence
Research 24 (2005): 195-220.

[2] Ross, S., J. Pineau, S. Paquet, and B. Chaib-draa. "Online
planning algorithms for POMDPs." Journal of Artificial Intelligence
Research 32 (2008): 663-704.

[4] Hansen, Eric A. "Solving POMDPs by Searching in Policy Space"
(1998): 211-219.

[5] Poupart, Pascal. "Exploiting structure to efficiently solve large
scale partially observable markov decision processes." University of
Toronto, 2005.

[6] Milos Hauskrecht, "Value-function approximations for partially
observable Markov decision processes." Journal of Artificial
Intelligence Research (2000).

[7] T. Smith and R. Simmons, "Heuristic search value iteration for
POMDPs." in Proceedings of the 20th conference on Uncertainty in
artificial intelligence, 2004, 520-527.

[8] Universal Java Matrix Package, http://www.ujmp.org/

[8] matrix-toolkits-java, http://code.google.com/p/matrix-toolkits-java/
