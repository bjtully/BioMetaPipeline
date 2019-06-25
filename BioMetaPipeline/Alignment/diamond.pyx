# cython: language_level=3

import luigi
import os
import subprocess
from BioMetaPipeline.Accessories.ops import get_prefix
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Parsers.blast_to_fasta import blast_to_fasta


class DiamondConstants:
    DIAMOND = "DIAMOND"
    OUTPUT_DIRECTORY = "diamond"


class Diamond(LuigiTaskClass):
    outfile = luigi.Parameter()
    output_directory = luigi.Parameter()
    program = luigi.Parameter(default="blastx")
    diamond_db = luigi.Parameter()
    query_file = luigi.Parameter()
    evalue = luigi.Parameter(default="1e-15")

    def run(self):
        assert str(self.program) in {"blastx", "blastp"}, "Invalid program passed"
        cdef tuple outfmt = ("--outfmt", "6", "qseqid", "sseqid", "qstart", "qend", "pident", "evalue")
        subprocess.run(
            [
                str(self.calling_script_path),
                str(self.program),
                "-d",
                str(self.diamond_db),
                "-q",
                str(self.query_file),
                "-o",
                os.path.join(str(self.output_directory), str(self.outfile)),
                *outfmt,
                "--evalue",
                str(self.evalue),
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))


class DiamondMakeDB(LuigiTaskClass):
    output_directory = luigi.Parameter()
    prot_file = luigi.Parameter()

    def run(self):
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        subprocess.run(
            [
                str(self.calling_script_path),
                "makedb",
                "--in",
                str(self.prot_file),
                "-d",
                os.path.join(str(self.output_directory), get_prefix(str(self.prot_file))),
            ],
            check=True,
        )

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), get_prefix(str(self.prot_file)) + ".dmnd"))


class DiamondToFasta(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    fasta_file = luigi.Parameter()
    diamond_file = luigi.Parameter()
    evalue = luigi.Parameter(default="1e-15")

    def run(self):
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        blast_to_fasta(
            str(self.fasta_file),
            str(self.diamond_file),
            os.path.join(str(self.output_directory), str(self.outfile)),
            e_value=float(str(self.evalue)),
        )


    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))
