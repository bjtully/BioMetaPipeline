# cython: language_level=3
import luigi
import os
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass


class SignalPConstants:
    SIGNALP = "SIGNALP"
    OUTPUT_DIRECTORY = "signalp_results"
    RESULTS_SUFFIX = ".signalp.tbl"


class SignalP(LuigiTaskClass):
    prot_file = luigi.Parameter()
    membrane_type = luigi.Parameter()
    output_directory = luigi.Parameter()
    outfile = luigi.Parameter()

    def requires(self):
        return []

    def run(self):
        cdef str status = "Beginning SignalP.........."
        print(status)
        if not os.path.exists(str(self.output_directory)):
            os.makedirs(str(self.output_directory))
        cdef list data_type_flags
        if str(self.membrane_type).lower() == "gram+":
            data_type_flags = ["-t", "gram+"]
        else:
            data_type_flags = ["-t", "gram-"]
        subprocess.run(
            [
                str(self.calling_script_path),
                *data_type_flags,
                str(self.prot_file),
            ],
            check=True,
            stdout=open(os.path.join(str(self.output_directory), str(self.outfile)), "w"),
        )
        print("%s%s" % (status[:-5],"done!"))

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.outfile)))