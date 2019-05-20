# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Parsers.fasta_parser import FastaParser


class ProdigalConstants:
    PRODIGAL = "PRODIGAL"
    OUTPUT_DIRECTORY = "prodigal_results"
    PROTEIN_FILE_SUFFIX = ".protein.faa"
    MRNA_FILE_SUFFIX = ".mrna.fna"


class Prodigal(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    protein_file_suffix = luigi.Parameter(default=ProdigalConstants.PROTEIN_FILE_SUFFIX)
    mrna_file_suffix = luigi.Parameter(default=ProdigalConstants.MRNA_FILE_SUFFIX)
    fasta_file = luigi.Parameter()
    run_edit = luigi.BoolParameter(default=True)

    def requires(self):
        return []

    def run(self):
        cdef str prot_out = os.path.join(str(self.output_directory),
                           str(self.outfile) +  ".tmp" + str(self.protein_file_suffix))
        cdef str prot_simple = os.path.join(str(self.output_directory),
                           str(self.outfile) + str(self.protein_file_suffix))
        cdef str mrna_out = os.path.join(str(self.output_directory),
                          str(self.outfile) + ".tmp" + str(self.mrna_file_suffix))
        cdef str mrna_simple = os.path.join(str(self.output_directory),
                          str(self.outfile) + str(self.mrna_file_suffix))
        subprocess.run(
            [str(self.calling_script_path),
             "-a",
             prot_out,
             "-d",
             mrna_out,
             "-o",
             os.path.join(str(self.output_directory), str(self.outfile) + ".txt"),
             *self.added_flags,
             "-i",
             str(self.fasta_file)],
            check=True,
        )
        # Run file edit is needed
        if bool(self.run_edit):
            FastaParser.write_simple(prot_out, prot_simple)
            os.remove(prot_out)
            FastaParser.write_simple(mrna_out, mrna_simple)
            os.remove(mrna_out)

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory),
                           str(self.outfile) + str(self.protein_file_suffix)))
