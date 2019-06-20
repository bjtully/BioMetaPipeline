#! /usr/bin/env python
import sys
from Bio import SeqIO

x = open(sys.argv[1])
GeneIdentifiers = [line.rstrip('\n') for line in x]
x.close()
record_dict = SeqIO.index(sys.argv[2],"fasta")
for id_ in GeneIdentifiers:
        print(record_dict[id_].format("fasta"))
