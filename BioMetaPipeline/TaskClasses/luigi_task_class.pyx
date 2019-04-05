import luigi


class LuigiTaskClass(luigi.Task):
    fasta_folder = luigi.Parameter()
    calling_script_path = luigi.Parameter()
    added_flags = luigi.ListParameter(default=[])
    output_directory = luigi.Parameter(default="outdir")
    outfile = luigi.Parameter(default="out")
