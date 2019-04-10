# cython: language_level=3

from BioMetaPipeline.Parsers.tsv_parser import TSVParser
from BioMetaPipeline.Parsers.checkm_parser import CheckMParser

"""
Class will combine .tsv output from CheckM and FastANI
Will output dictionary as:
    
    {
    "id":   {
                "non_redundant":        bint,
                "redundant_copies":     list,
                "contamination":        float,
                "is_contaminated":      bint,
                "completion":           float,
                "is_complete":          bint,
                "phylogeny_string":     str,
            }
    }

"""


cdef class RedundancyChecker:
    cdef void* checkm_file
    cdef void* fastani_file

    def __init__(self, str checkm_filename, str fastani_filename, dict cutoff_values):
        self.checkm_file = <void *>checkm_filename
        self.fastani_file = <void *>fastani_filename
        self.cutoffs = cutoff_values

    def _parse_records_to_categories(self):
        cdef dict checkm_results = CheckMParser.parse_dict(<object>self.checkm_file)
        cdef dict fastANI_results = TSVParser.parse_dict(<object>self.fastani_file)
        cdef set record_ids = set(*[checkm_results.keys()], *[fastANI_results.keys()])
        cdef dict to_return = {}
        cdef str key
        for key in record_ids:
            # Assign by CheckM output
            to_return[key] = {}
            # Completion value
            to_return[key]["completion"] = float(checkm_results[key][0])
            # Set boolean based on CUTOFF values
            if to_return[key]["completion"] < float(self.cutoffs["IS_COMPLETE"]):
                to_return[key]["is_complete"] = False
            else:
                to_return[key]["is_complete"] = True
            # Contamination value
            to_return[key]["contamination"] = float(checkm_results[key][1])
            # Se boolean based on CUTOFF values
            if to_return[key]["contamination"] < float(self.cutoffs["IS_CONTAMINATED"]):
                to_return[key]["is_contaminated"] = False
            else:
                to_return[key]["is_contaminated"] = True
            # Assign redundancy by fastANI:
            #   If not on fastANI

    def _write_tsv(self):
        pass
