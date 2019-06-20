#!/usr/bin/python

'''
Goes through and reads the tabular output output from hmmsearch then builds a dictionary of dictionary with counts and converts it to a tab delimited file.
'''
import sys
import pandas as pd
genome_matches = {}
cazy_ids = []

for line in open(sys.argv[1], "r"):
	line = line.strip()
	if line[0] != "#":
		data = line.split()
		genome = data[0].split("_")[0]
		cazy = str(data[2].split(".")[0])
		if cazy not in cazy_ids:
			cazy_ids.append(cazy)
		if genome not in genome_matches.keys():
			genome_matches[genome] = {cazy:1}
		if genome in genome_matches.keys():
			if cazy in genome_matches[genome].keys():
				genome_matches[genome][cazy] += 1
			if cazy not in genome_matches[genome].keys():
				genome_matches[genome][cazy] = 1


final = (pd.DataFrame.from_records(genome_matches)).fillna(0).T
final.to_csv(sys.argv[2],sep='\t')

