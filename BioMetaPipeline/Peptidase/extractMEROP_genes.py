#! /usr/bin/env python
import sys

MEROPSresults=[]
with open(sys.argv[1]) as f:
	content = [line.rstrip('\n') for line in f]
	for y in content:
		MEROPSresults.append(y.split(" "))			
MEROPSresults = [filter(None,l) for l in MEROPSresults]
# print MEROPSresults
MEROPSresults=MEROPSresults[:-10]
MEROPSresults=MEROPSresults[3:]
geneNames = []
for f in MEROPSresults:
	geneNames.append(f[0])
geneNames= set(geneNames)
for f in geneNames:
	print(f)
