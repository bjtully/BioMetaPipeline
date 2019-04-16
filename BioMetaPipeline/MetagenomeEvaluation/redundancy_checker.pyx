# cython: language_level=3
from BioMetaPipeline.Parsers.tsv_parser import TSVParser
from BioMetaPipeline.Parsers.checkm_parser import CheckMParser
import luigi
import os
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.MetagenomeEvaluation.fastani import FastANIConstants

"""
Class will combine .tsv output from CheckM and FastANI
Will output dictionary as:
    
    {
    "id":   {
                "is_non_redundant":     bint,
                "redundant_copies":     list,
                "contamination":        float,
                "is_contaminated":      bint,
                "completion":           float,
                "is_complete":          bint,
                "phylogeny":     str,
            }
    }

"""


cdef class RedundancyChecker:
    cdef void* checkm_file
    cdef void* fastani_file
    cdef void* gtdbtk_file
    cdef dict cutoffs
    cdef dict output_data
    cdef dict file_ext_dict

    def __init__(self, str checkm_filename, str fastani_filename, str gtdbtk_filename, dict cutoff_values, dict file_ext_dict):
        if not os.path.isfile(checkm_filename) or not os.path.isfile(fastani_filename) or not os.path.isfile(gtdbtk_filename):
            raise FileNotFoundError
        self.cutoffs = cutoff_values
        self.checkm_file = <void *>checkm_filename
        self.fastani_file = <void *>fastani_filename
        self.gtdbtk_file = <void *>gtdbtk_filename
        self.output_data = {}
        self.file_ext_dict = file_ext_dict
        self._parse_records_to_categories()

    def _parse_records_to_categories(self):
        print(<object>self.checkm_file, <object>self.fastani_file, <object>self.gtdbtk_file)
        cdef dict checkm_results = CheckMParser.parse_dict(<object>self.checkm_file)
        cdef dict fastANI_results = TSVParser.parse_dict(<object>self.fastani_file)
        cdef dict gtdbktk_results = TSVParser.parse_dict(<object>self.gtdbtk_file)
        cdef str key
        cdef str max_completion_id
        cdef float max_completion
        cdef int i
        cdef object fast_ANI_keys = fastANI_results.keys()
        cdef str redundant_copies_str = "redundant_copies"
        cdef str completion_str = "completion"
        cdef str is_complete_str = "is_complete"
        cdef str is_contaminated_str = "is_contaminated"
        cdef str contamination_str = "contamination"
        cdef str is_non_redundant_str = "is_non_redundant"
        cdef str phylogeny_str = "phylogeny"
        cdef str fastani_key
        cdef str key_and_ext
        for key in checkm_results.keys():
            # Assign by CheckM output
            key_and_ext = self.file_ext_dict[key]
            self.output_data[key_and_ext] = {}
            # Set gtdbtk value
            self.output_data[key_and_ext][phylogeny_str] = gtdbktk_results[key][0]
            # Initialize empty redundancy list
            self.output_data[key_and_ext][redundant_copies_str] = []
            # Completion value
            self.output_data[key_and_ext][completion_str] = float(checkm_results[key][0])
            # Set boolean based on CUTOFF values
            if self.output_data[key_and_ext][completion_str] < float(self.cutoffs["IS_COMPLETE"]):
                self.output_data[key_and_ext][is_complete_str] = False
            else:
                self.output_data[key_and_ext][is_complete_str] = True
            # Contamination value
            self.output_data[key_and_ext][contamination_str] = float(checkm_results[key][1])
            # Set boolean based on CUTOFF values
            if self.output_data[key_and_ext][contamination_str] < float(self.cutoffs["IS_CONTAMINATED"]):
                self.output_data[key_and_ext][is_contaminated_str] = False
            else:
                self.output_data[key_and_ext][is_contaminated_str] = True
            # Assign redundancy by fastANI:
            # If not on fastANI report, mark as non_redundant
            # Rename key to include file ext
            fastani_key = FastANIConstants.OUTPUT_DIRECTORY + "/" + self.file_ext_dict[key]
            if fastani_key not in fast_ANI_keys:
                self.output_data[key_and_ext][is_non_redundant_str] = True
            # If not from identical match, store to list of redundant copies
            else:
                if fastANI_results[fastani_key][0] != fastani_key:
                    if float(fastANI_results[fastani_key][1]) > float(self.cutoffs["ANI"]):
                        self.output_data[key_and_ext][redundant_copies_str].append(fastANI_results[fastani_key][0])

        # Update each key with a redundancy list to set non_redundant values for most complete
        for key in self.output_data.keys():
            if len(self.output_data[key][redundant_copies_str]) > 0:
                # Set max completion as first value
                max_completion = self.output_data[self.output_data[key][redundant_copies_str][0]][completion_str]
                # Get id of max completion
                max_completion_id = self.output_data[key][redundant_copies_str][0]
                for i in range(len(self.output_data[key][redundant_copies_str])):
                    # Update max completion percent as needed
                    if self.output_data[self.output_data[key][redundant_copies_str][i]][completion_str] > max_completion:
                        max_completion = self.output_data[self.output_data[key][redundant_copies_str][i]][completion_str]
                        max_completion_id = self.output_data[key][redundant_copies_str][i]
                # Move through list of redundant copies and set redundancy as needed
                for i in range(len(self.output_data[key][redundant_copies_str])):
                    if self.output_data[key][redundant_copies_str][i] == max_completion_id:
                        self.output_data[self.output_data[key][redundant_copies_str][i]][is_non_redundant_str] = True
                    else:
                        self.output_data[self.output_data[key][redundant_copies_str][i]][is_non_redundant_str] = False

    def write_tsv(self, str file_name):
        """ Method will write all values in self.output_data to .tsv file

        :return:
        """
        cdef object W = open(file_name, "w")
        cdef str _id
        cdef str column_name
        # Write header
        W.write("ID")
        cdef list column_names = list(self.output_data[list(self.output_data.keys())[0]].keys())
        for column_name in column_names:
            W.write("\t%s" % column_name)
        W.write("\n")
        # Write each line
        for _id in self.output_data.keys():
            W.write(_id)
            for column_name in column_names:
                W.write("\t%s" % self.output_data[_id][column_name])
            W.write("\n")
        W.close()


class RedundancyParserTask(LuigiTaskClass):
    checkm_output_file = luigi.Parameter()
    fastANI_output_file = luigi.Parameter()
    gtdbtk_output_file = luigi.Parameter()
    cutoffs_dict = luigi.DictParameter()
    output_directory = luigi.Parameter(default="out")
    outfile = luigi.Parameter()
    file_ext_dict = luigi.DictParameter()

    def requires(self):
        return []

    def run(self):
        rc = RedundancyChecker(str(self.checkm_output_file),
                               str(self.fastANI_output_file),
                               str(self.gtdbtk_output_file),
                               dict(self.cutoffs_dict),
                               dict(self.file_ext_dict))
        rc.write_tsv(self.outfile)

    def output(self):
        return luigi.LocalTarget(self.outfile)


