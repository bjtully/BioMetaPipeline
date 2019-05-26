# cython: language_level=3
import luigi
import os
import shutil
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Annotation.FunctionalProfileReader.reader import KoFamScan


class KofamScanConstants:
    KOFAMSCAN = "KOFAMSCAN"
    OUTPUT_DIRECTORY = "kofamscan_results"
    TMP_DIR = "tmp"

class KofamScan(LuigiTaskClass):
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()
    fasta_file = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        cdef str outfile_path = os.path.join(str(self.output_directory), str(self.outfile) + ".tmp.tsv")
        cdef str outpath = os.path.join(str(self.output_directory), str(self.outfile) + ".tsv")
        cdef str tmp_path = os.path.join(str(self.output_directory), KofamScanConstants.TMP_DIR)
        subprocess.run(
            [
                str(self.calling_script_path),
                "-o",
                outfile_path,
                "--tmp-dir",
                tmp_path,
                *self.added_flags,
                str(self.fasta_file),
            ],
            check=True,
        )
        KoFamScan.write_highest_matches(
            outfile_path,
            outpath
        )
        # Remove temp directory and file
        os.remove(outfile_path)
        shutil.rmtree(tmp_path)

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile) + ".tsv"))
