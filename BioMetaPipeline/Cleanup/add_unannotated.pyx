# cython: language_level=3
import os
import luigi
import pandas
from string import punctuation

unusable_punctuation = set(punctuation) - {"-",}

def correct_val(str val):
    """ Method will make each value in iterable SQL-safe

    :param val:
    :return:
    """
    cdef str bad_char
    cdef str new_val = val.lower()
    for bad_char in unusable_punctuation:
        new_val = new_val.replace(bad_char, "")
    new_val = new_val.replace(" ", "-")
    new_val = new_val.replace("_", "-")
    return new_val

class AddUnannotated(luigi.Task):
    fasta_prefix = luigi.Parameter()
    biometadb_project = luigi.Parameter()
    proteins_directory = luigi.Parameter()
    annotation_tsv_outfile = luigi.Parameter()
    output_file = luigi.Parameter()
    output_directory = luigi.Parameter()
    delimiter = luigi.Parameter(default="\t")

    def requires(self):
        return []

    def run(self):
        cdef list combined_results
        cdef str _file, prot_id, annotation
        cdef set all_proteins = set(os.listdir(str(self.proteins_directory)))
        cdef set stored_prots = set(os.listdir(os.path.join(str(self.biometadb_project), "db", correct_val(os.path.basename(str(self.proteins_directory))))))
        cdef list columns_to_update = next(open(str(self.annotation_tsv_outfile), "r")).rstrip("\r\n").split("\t")[1:]
        combined_results = [pandas.read_csv(str(self.annotation_tsv_outfile), delimiter=str(self.delimiter), header=0, index_col=0),]
        for prot_id in all_proteins - stored_prots:
            combined_results.append(pandas.DataFrame(data={annotation: "None" for annotation in columns_to_update}, columns=columns_to_update, index=[prot_id,]))
        pandas.concat(combined_results, sort=True).to_csv(
                        os.path.join(str(self.output_directory), str(self.output_file)),
                        sep="\t",
                        na_rep="None",
                        index=True,
                        index_label="ID",
                    )
    
    def output(self):
        pass
