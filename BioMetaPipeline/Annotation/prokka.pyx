# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Parsers.tsv_parser import TSVParser
from BioMetaPipeline.Accessories.ops import get_prefix


class PROKKAConstants:
    PROKKA = "PROKKA"
    OUTPUT_DIRECTORY = "prokka_results"
    AMENDED_RESULTS_SUFFIX = ".amended.tsv"


class PROKKA(LuigiTaskClass):
    output_directory = luigi.Parameter()
    out_prefix = luigi.Parameter()
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        cdef str outfile_prefix = get_prefix(str(self.fasta_file))
        if not os.path.isfile(os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".tsv")):
            subprocess.run(
                [
                    str(self.calling_script_path),
                    "--prefix",
                    str(self.out_prefix),
                    "--outdir",
                    os.path.join(str(self.output_directory), outfile_prefix),
                    str(self.fasta_file),
                    *self.added_flags,
                ],
                check=True,
            )
        write_prokka_amended(
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + ".tsv"),
            os.path.join(str(self.output_directory), outfile_prefix, outfile_prefix + PROKKAConstants.AMENDED_RESULTS_SUFFIX)
        )

    def output(self):
        return luigi.LocalTarget(
            os.path.join(str(self.output_directory),
                         get_prefix(str(self.fasta_file)),
                         get_prefix(str(self.fasta_file)) + PROKKAConstants.AMENDED_RESULTS_SUFFIX)
        )


cdef void write_prokka_amended(str prokka_results, str outfile):
    """ Shortens output from prokka to only be CDS identifiers
    
    :param prokka_results: 
    :param outfile: 
    :return: 
    """
    cdef object tsvParser = TSVParser(prokka_results)
    # Call through object to retain header line
    tsvParser.read_file(header_line=True)
    cdef list prokka_data = tsvParser.get_values()
    cdef object W = open(outfile, "w")
    cdef str current_id = prokka_data[0][0]
    cdef list prokka_inner_list
    cdef str val, out_string = ""
    # Write Header
    W.write(tsvParser.header())
    W.write("\n")
    for prokka_inner_list in prokka_data:
        if prokka_inner_list[1] == "CDS":
            for val in prokka_inner_list:
                out_string += val + "\t"
            W.write(out_string[:-1])
            W.write("\n")
            out_string = ""
    W.close()
