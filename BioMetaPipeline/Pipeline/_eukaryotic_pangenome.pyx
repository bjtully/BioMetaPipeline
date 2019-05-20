# cython: language_level=3
import os
import luigi
from BioMetaPipeline.DataPreparation.zip import Gunzip
from BioMetaPipeline.DataPreparation.zip import GZip
from BioMetaPipeline.DataPreparation.dedup import SingleEnd, DedupConstants
from BioMetaPipeline.DataPreparation.trim import TrimSingle, TrimConstants
from BioMetaPipeline.Alignment.bowtie import Bowtie2Single, Bowtie2Constants
from BioMetaPipeline.Alignment.sambamba import View, Sort, SambambaConstants
from BioMetaPipeline.FileOperations.file_operations import Remove
from BioMetaPipeline.Pipeline.Exceptions.GeneralAssertion import AssertString
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.PipelineManagement.run_manager import RunManager

"""
eukaryotic_pangenome runs extended assembly pipeline 
Uses raw sequence reads .fastq



    Alignment-based
    
    Denovo

"""


class EukaryoticPangenomeConstants:
    EUKARYOTIC_PANGENOME_PROJECT_NAME = "EukaryoticPangenome"


def eukaryotic_pangenome(str directory, str config_file, bint cancel_autocommit, str output_directory,
                         str biometadb_project, str list_file):
    """

    :param directory:
    :param config_file:
    :param cancel_autocommit:
    :param output_directory:
    :param biometadb_project:
    :param list_file:
    :return:
    """
    assert os.path.exists(directory) and os.path.exists(config_file) and os.path.exists(list_file), \
        AssertString.INVALID_PARAMETERS_PASSED
    cdef object cfg = ConfigManager(config_file)
    cdef object rm = RunManager(list_file)
    cdef object line_data
    cdef list task_list = []
    cdef str fastq_file
    if not os.path.exists(output_directory):
        # Output directory
        os.makedirs(output_directory)
        for val in (DedupConstants, Bowtie2Constants, TrimConstants, SambambaConstants):
            os.makedirs(os.path.join(output_directory, str(getattr(val, "OUTPUT_DIRECTORY"))))
    line_data = rm.get()
    while line_data:
        for fastq_file in line_data[1]:
            zipped_file_and_path = os.path.join(directory, fastq_file)
            unzipped_file_and_path = os.path.splitext(zipped_file_and_path)[0]
            task_list.append(Gunzip(zipped_file=zipped_file_and_path))
            single_end = SingleEnd(calling_script_path=cfg.get(DedupConstants.DEDUP, ConfigManager.PATH),
                                   zipped_file=zipped_file_and_path,
                                   added_flags=cfg.build_parameter_list_from_dict(DedupConstants.DEDUP),
                                   output_directory=os.path.join(output_directory, DedupConstants.OUTPUT_DIRECTORY))
            task_list.append(single_end)
            trim_single = TrimSingle(added_flags=cfg.build_parameter_list_from_dict(TrimConstants.TRIM),
                                     output_directory=os.path.join(output_directory, TrimConstants.OUTPUT_DIRECTORY),
                                     calling_script_path=cfg.get(TrimConstants.TRIM, ConfigManager.PATH),
                                     data_file=single_end.output().path)
            task_list.append(trim_single)
            bowtie2_single = Bowtie2Single(
                calling_script_path=cfg.get(Bowtie2Constants.BOWTIE2, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, Bowtie2Constants.OUTPUT_DIRECTORY),
                data_file=trim_single.output().path,
                index_file=cfg.get(Bowtie2Constants.BOWTIE2, Bowtie2Constants.BOWTIE2_INDEX_PATH),
                added_flags=cfg.build_parameter_list_from_dict(Bowtie2Constants.BOWTIE2),
                output_prefix=line_data[0])
            task_list.append(bowtie2_single)
            sambamba_view = View(
                calling_script_path=cfg.get(SambambaConstants.SAMBAMBA, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, SambambaConstants.OUTPUT_DIRECTORY),
                added_flags=cfg.build_parameter_list_from_dict(SambambaConstants.SAMBAMBA),
                sam_file=bowtie2_single.output().path
            )
            task_list.append(sambamba_view)
            sambamba_sort = Sort(
                calling_script_path=cfg.get(SambambaConstants.SAMBAMBA, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, SambambaConstants.OUTPUT_DIRECTORY),
                added_flags=cfg.build_parameter_list_from_dict(SambambaConstants.SAMBAMBA),
                bam_file=sambamba_view.output().path
            )
            task_list.append(sambamba_sort)
            # task_list.append(Remove(data_files=[
            #     single_end.output().path,
            #     trim_single.output().path,
            #     os.path.splitext(single_end.output().path)[0] + ".dropB",
            #     sambamba_view.output().path
            # ]))
            task_list.append(GZip(unzipped_file=unzipped_file_and_path))
        line_data = rm.get()
    luigi.build(task_list, local_scheduler=True)
