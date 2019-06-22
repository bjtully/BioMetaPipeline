#!/usr/bin/python
import pandas as pd
import sys

# READ IN PSORTB DATA
psortb = pd.read_csv(sys.argv[1], sep="\t", index_col=False, comment="#")
# generate two new databases with only extracellular calls and only unknown calls
psortb_extracellular = psortb[(psortb.values == "Extracellular") | (psortb.values == "Cellwall")]
psortb_unknown = psortb[(psortb.values == "Unknown")]
# Create a list of gene ids marked as extracellular or unknown
psortbExtracellularResults = psortb_extracellular["SeqID"].values
psortbUnknownResults = psortb_unknown["SeqID"].values
psortbExtracellularResults = [result.strip().replace(" ", "") for result in psortbExtracellularResults]
# print psortb_extracellular.head()
# print psortb_unknown.head()

# READ IN SIGNALP RESULTS
signalp = pd.read_csv(sys.argv[2], sep="\t", index_col=False, comment="#",
                      names=["name", "Cmax", "pos1", "Ymax", "pos2", "Smax", "pos3", "Smean", "D", "Answer", "Dmaxcut",
                             "Networks-used"])
# Create list of gene ids with Yes from signalp
signalP_Yes = signalp[(signalp.Answer.values == "Y")]
signalp_results = signalP_Yes["name"].values
signalp_results = [result.strip().replace(" ", "") for result in signalp_results]
finalExtracellularList = set(signalp_results + psortbExtracellularResults)
# READ IN MEROPS DATA
MEROPS = pd.read_csv(sys.argv[3], sep="\t", index_col=False, comment='#',
                     names=["target_name", "accession_target", "query_name", "accession_query", "E-value_FullSeq",
                            "score_FullSeq", "bias_FullSeq", "E-value_Best1Domain", "score_Best1Domain",
                            "bias_Best1Domain", "exp", "reg", "clu", "ov", "env", "dom", "rep", "inc", "gene",
                            "description"])
# CREATE DICT WITH KEY BEING THE GENE CALL AND VALUE BEING THE PFAM
TargetToPFAM = pd.Series(MEROPS.accession_query.values, index=MEROPS.target_name).to_dict()
TargetToPFAM = {k.strip(): v.strip().split('.')[0] for k, v in TargetToPFAM.iteritems()}
# CREATE DICT CONTAINING ONLY THOSE GENE CALLS THAT ARE EXTRACELLULAR WHERE THE KEY IS THE GENE AND THE VALUE IS THE PFAM
ExtraCellPFAM_dict = dict([(k, TargetToPFAM[k]) for k in finalExtracellularList])
# CREATE A NEW LIST OF ALL THE GENOMES OF INTEREST (ASSUMES THAT YOUR Gene IS IN THE FORMAT GENOME12_GENECALL1)
finalExtracellularList_Genomes = set([genename.split("_")[0] for genename in finalExtracellularList])
# CREATE AN EMPTY DICT TO POPULATE WITH EXTRACELLULAR PROTEIN PFAMS
GenomeDict = {k: [] for k in finalExtracellularList_Genomes}
# pOPULATE EMPTY DICT ABOVE WITH APPROPRIATE PFAM VALUES FOR EACH GENOME
for key, value in ExtraCellPFAM_dict.iteritems():
    genome = key.split("_")[0]
    GenomeDict[genome].append(value)
# CREATE A FINAL COUNT TABLE WITH PFAMS
FinalCountTablePFAM = pd.DataFrame.from_dict(GenomeDict, orient='index').stack().str.get_dummies().sum(
    level=0).sort_index()
FinalCountTablePFAM.to_csv(sys.argv[4], index_label=False, sep="\t")
# CREATE MEROPS CONVERSION DICT
merops_conversion = {}
for line in open(sys.argv[7], "r"):
    line = line.strip()
    if line[:6] != "Family":
        data = line.split("\t")
        merops_conversion[data[3]] = str(data[0]) + "." + str(data[1])
# Convert PFAMS to MEROPS Identifier

MeropsConvertedDF = FinalCountTablePFAM.rename(columns=merops_conversion)
MeropsConvertedDF.to_csv(sys.argv[5], sep="\t")
# Populate empty columns
AmmendedMeropsConvertedDF = MeropsConvertedDF
merops_conversion_values = merops_conversion.values()
for m in merops_conversion_values:
    if m not in MeropsConvertedDF.columns:
        AmmendedMeropsConvertedDF[m] = 0
AmmendedMeropsConvertedDF.to_csv(sys.argv[6], sep="\t")
