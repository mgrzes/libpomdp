'''
 libpomdp
 ========
 File: gen_rs_10_10.py
 Description: jython script to generate RockSample[10,10]
 Copyright (c) 2009, 2010, 2011 Diego Maniloff 
'''

# imports
import sys
sys.path.append('../../../../dist/libpomdp.jar')
import java.io.PrintStream as PrintStream
from libpomdp.problems.rocksample.java import *

# declarations
out = PrintStream("10-10/RockSample_10_10.SPUDD")
n   = 10
k   = [ [0, 3],
        [0, 7],
        [1, 8],
        [3, 3],
        [3, 8],
        [4, 3],
        [5, 8],
        [6, 1],
        [9, 3],
        [9, 9], ]
apos = [0,5]

# generate
gen = RocksampleGen(n, k, apos, out)
