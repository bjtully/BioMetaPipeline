# cython: language_level=3
import luigi
import os
from BioMetaPipeline.Accessories.ops import get_prefix
import subprocess
from BioMetaPipeline.TaskClasses.luigi_task_class import LuigiTaskClass
from BioMetaPipeline.Parsers.tsv_parser import TSVParser


class InterproscanConstants:
    INTERPROSCAN = "INTERPROSCAN"
    OUTPUT_DIRECTORY = "interproscan_results"
    AMENDED_RESULTS_SUFFIX = ".amended.tsv"


class Interproscan(LuigiTaskClass):
    output_directory = luigi.Parameter()
    out_prefix = luigi.Parameter()
    fasta_file = luigi.Parameter()
    applications = luigi.ListParameter()

    def requires(self):
        return []

    def run(self):
        cdef str outfile_name = os.path.join(str(self.output_directory), get_prefix(str(self.fasta_file)))
        cdef object outfile = open(outfile_name, "w")
        subprocess.run(
            [
                "sed",
                "s/\*//g",
                str(self.fasta_file),
            ],
            check=True,
            stdout=outfile,
        )
        subprocess.run(
            [
                str(self.calling_script_path),
                "-i",
                os.path.abspath(outfile_name),
                "-o",
                os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"),
                "-f",
                "tsv",
                *self.added_flags
            ],
            check=True,
        )
        write_interproscan_amended(
            os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"),
            os.path.join(str(self.output_directory), str(self.out_prefix) + InterproscanConstants.AMENDED_RESULTS_SUFFIX),
            list(self.applications)
        )
        os.remove(outfile_name)

    def output(self):
        return luigi.LocalTarget(os.path.join(str(self.output_directory), str(self.out_prefix) + ".tsv"))


cdef void write_interproscan_amended(str interproscan_results, str outfile,  list applications):
    """ Function will write a shortened tsv version of the interproscan results in which
    columns are the applications that were run by the user
    
    :param applications:
    :param interproscan_results:
    :param outfile: 
    :return: 
    """
    # interproscan indices are 0:id; 3:application; 4:sign_accession; 6:start_loc; 7:stop_loc; 11:iprlookup(opt);
    #                           13:goterms(opt); 14:pathways(opt)
    cdef tuple col_list = (0, 3, 4, 6, 7, 11, 13, 14)
    cdef int val
    cdef object app
    cdef list interpro_results_list = TSVParser.parse_list(interproscan_results, col_list=col_list)
    cdef object W = open(outfile, "w")
    # initialize current id with first value from interproscan list
    cdef str current_id = interpro_results_list[0][0]
    cdef list interpro_inner_list
    cdef dict application_results = {str(app): "" for app in applications}
    # Write header
    W.write("Protein")
    for app in applications:
        W.write("\t" + str(app))
    W.write("\n")
    # Write results by application
    for interpro_inner_list in interpro_results_list:
        # Reset prior dict
        # interproscan outputs results for all applications before moving to next protein
        # Collect line info in application until the id changes to the new protein id
        if interpro_inner_list[0] == current_id:
            application_results[interpro_inner_list[1]] = "%s-%s:%s" % (
                interpro_inner_list[2],
                interpro_inner_list[3],
                interpro_inner_list[4],
            )
        else:
            # results of protein application end; write to file and move to next protein
            for app in applications:
                W.write("\t" + application_results[app])
            W.write("\n")
            application_results = {str(app): "" for app in applications}
    W.close()
