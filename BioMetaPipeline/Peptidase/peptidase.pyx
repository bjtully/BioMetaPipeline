# distutils: language = c++
import os
import luigi
from collections import Counter
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from libcpp.string cimport string


cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)



class PeptidaseConstants:
    PEPTIDASE = "PEPTIDASE"
    OUTPUT_DIRECTORY = "peptidase_results"
    EXTRACELLULAR_MATCHES_EXT = ".pfam.tsv"
    EXTRACELLULAR_MATCHES_BYPROT_EXT = ".pfam.by_prot.tsv"
    MEROPS_HITS_EXT = ".merops.tsv"


class Peptidase(LuigiTaskClass):
    psortb_results = luigi.Parameter()
    signalp_results = luigi.Parameter()
    merops_hmm_results = luigi.Parameter()
    output_directory = luigi.Parameter()
    output_prefix = luigi.Parameter()
    protein_suffix = luigi.Parameter()
    genome_id_and_ext = luigi.Parameter()
    pfam_to_merops_dict = luigi.DictParameter()

    def requires(self):
        return []

    def run(self):
        cdef object psortb_data = open(str(self.psortb_results), "rb")
        cdef object signalp_results = open(str(self.signalp_results), "rb")
        cdef object merops_results = open(str(self.merops_hmm_results), "rb")
        cdef object pfam_prot_out = open(os.path.join(
            str(self.output_directory),
            str(self.output_prefix) + PeptidaseConstants.EXTRACELLULAR_MATCHES_BYPROT_EXT,
        ), "wb")
        cdef object pfam_count_out = open(os.path.join(
            str(self.output_directory),
            str(self.output_prefix) + PeptidaseConstants.EXTRACELLULAR_MATCHES_EXT,
        ), "wb")
        cdef object merops_count_out = open(os.path.join(
            str(self.output_directory),
            str(self.output_prefix) + PeptidaseConstants.MEROPS_HITS_EXT,
        ), "wb")
        cdef bytes _line, _id, pfam, merop
        cdef str key, val
        cdef int count
        cdef list line, pfams, merops,
        cdef set matched_protein_ids = set()
        cdef dict extracellular_pfams = {}
        cdef dict extracellular_pfam_counts, merops_counts, adj_merops_pfam_dict
        # Gather psortb ids assigned as "Extracellular" or "Cell Wall"
        # Skip over header line
        next(psortb_data)
        for _line in psortb_data:
            line = _line.split(maxsplit=2)
            if line[1] in (b"Extracellular", b"Cellwall"):
                matched_protein_ids.add(line[0])
        psortb_data.close()
        # Gather signalp ids assigned "Y"
        # Skip over 2 header lines
        next(signalp_results)
        next(signalp_results)
        for _line in signalp_results:
            line = _line.split(maxsplit=10)
            if line[9] == b"Y":
                matched_protein_ids.add(line[0])
        signalp_results.close()
        # Gather hmm results for collected ids
        # Skip over 3 header lines
        next(merops_results)
        next(merops_results)
        next(merops_results)
        for _line in merops_results:
            line = _line.split(maxsplit=4)
            # Only include collected ids
            if line[0] in matched_protein_ids:
                extracellular_pfams[line[0]] = line[3].split(b".")[0]
        merops_results.close()
        # Write output table of proteins with extracellular matches
        pfam_prot_out.write(b"Protein\tMEROPS_Pfam\n")
        for _id, pfam in extracellular_pfams.items():
            pfam_prot_out.write(_id + <string>PyUnicode_AsUTF8(str(self.protein_suffix)) + b"\t" + pfam + b"\n")
        pfam_prot_out.close()
        # Write count table of pfam hits for entire genome
        extracellular_pfam_counts = <dict>Counter(extracellular_pfams.values())
        pfams = list(extracellular_pfam_counts.keys())
        pfam_count_out.write(b"Genome")
        for pfam in pfams:
            pfam_count_out.write(b"\t" + pfam)
        pfam_count_out.write(b"\n")
        pfam_count_out.write(<string>PyUnicode_AsUTF8(str(self.genome_id_and_ext)))
        for pfam in pfams:
            pfam_count_out.write(b"\t" + b"%i" % extracellular_pfam_counts[pfam])
        pfam_count_out.write(b"\n")
        pfam_count_out.close()
        # Write merops count info
        adj_merops_pfam_dict = {<string>PyUnicode_AsUTF8(key): <string>PyUnicode_AsUTF8(val) for key, val in self.pfam_to_merops_dict.items()}
        merops_counts = <dict>Counter({adj_merops_pfam_dict[pfam]: count for pfam, count in extracellular_pfam_counts.items()})
        merops = list(merops_counts.keys())
        merops_count_out.write(b"Genome")
        for merop in merops:
            merops_count_out.write(b"\t" + merop)
        merops_count_out.write(b"\n")
        merops_count_out.write(<string>PyUnicode_AsUTF8(str(self.genome_id_and_ext)))
        for merop in merops:
            merops_count_out.write(b"\t" + b"%i" % merops_counts[merop])
        merops_count_out.write(b"\n")
        merops_count_out.close()

    def output(self):
        return luigi.LocalTarget(os.path.join(
            str(self.output_directory),
            str(self.output_prefix) + PeptidaseConstants.EXTRACELLULAR_MATCHES_BYPROT_EXT,
        )), luigi.LocalTarget(os.path.join(
            str(self.output_directory),
            str(self.output_prefix) + PeptidaseConstants.EXTRACELLULAR_MATCHES_EXT,
        )), luigi.LocalTarget(os.path.join(
            str(self.output_directory),
            str(self.output_prefix) + PeptidaseConstants.MEROPS_HITS_EXT,
        ))