#!/usr/bin/env python3

import os
import luigi
from BioMetaPipeline.Accessories.arg_parse import ArgParse
from BioMetaPipeline.Accessories.run_manager import RunManager
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.DataPreparation.zip import Gunzip
from BioMetaPipeline.DataPreparation.zip import GZip
from BioMetaPipeline.DataPreparation.dedup import SingleEnd
from BioMetaPipeline.DataPreparation.trim import TrimSingle
from BioMetaPipeline.Alignment.bowtie import Bowtie2Single
from BioMetaPipeline.Alignment.sambamba import View, Sort
from BioMetaPipeline.FileOperations.file_operations import Remove
from BioMetaPipeline.FastQ_Alignment_to_Reference_constants import ConfigConstants


if __name__ == "__main__":
    args_list = (
        (("-c", "--config"),
         {"help": "/path/to/config_file formatted with ConfigParser standards", "require": True}),
        (("-l", "--list_file"),
         {"help": "/path/to/list_file formatted as 'prefix\\tdata_file_1,data_file_2...\\n'", "require": True}),
        (("-o", "--output_directory"),
         {"help": "Output directory prefix", "default": "out"})
    )
    ap = ArgParse(args_list, description="Alignment-Based Assembly BioMetaPipeline")
    cfg = ConfigManager(ap.args.config)
    rm = RunManager(ap.args.list_file)
    if not os.path.exists(ap.args.output_directory):
        os.makedirs(ap.args.output_directory)
    task_list = []
    line_data = rm.get()
    while line_data:
        for fastq_file in line_data[1]:
            zipped_file_and_path = os.path.join(cfg.get(ConfigConstants.DATA, ConfigConstants.PATH), fastq_file)
            unzipped_file_and_path = os.path.splitext(zipped_file_and_path)[0]
            task_list.append(Gunzip(zipped_file=zipped_file_and_path))
            single_end = SingleEnd(calling_script_path=cfg.get(ConfigConstants.DEDUP, ConfigConstants.DEDUP_PATH),
                                   zipped_file=zipped_file_and_path,
                                   added_flags=cfg.build_parameter_list_from_dict(ConfigConstants.DEDUP),
                                   output_directory=ap.args.output_directory)
            task_list.append(single_end)
            trim_single = TrimSingle(added_flags=cfg.build_parameter_list_from_dict(ConfigConstants.TRIMMOMATIC),
                                     output_directory=ap.args.output_directory,
                                     calling_script_path=cfg.get(ConfigConstants.TRIMMOMATIC,
                                                                 ConfigConstants.TRIMMOMATIC_PATH),
                                     data_file=single_end.output().path)
            task_list.append(trim_single)
            bowtie2_single = Bowtie2Single(
                calling_script_path=cfg.get(ConfigConstants.BOWTIE2, ConfigConstants.BOWTIE2_PATH),
                output_directory=ap.args.output_directory,
                data_file=trim_single.output().path,
                index_file=cfg.get(ConfigConstants.BOWTIE2, ConfigConstants.BOWTIE2_INDEX_PATH),
                added_flags=cfg.build_parameter_list_from_dict(ConfigConstants.BOWTIE2),
                output_prefix=line_data[0])
            task_list.append(bowtie2_single)
            sambamba_view = View(
                calling_script_path=cfg.get(ConfigConstants.SAMBAMBA, ConfigConstants.SAMBAMBA_PATH),
                output_directory=ap.args.output_directory,
                added_flags=cfg.build_parameter_list_from_dict(ConfigConstants.SAMBAMBA),
                sam_file=bowtie2_single.output().path
            )
            task_list.append(sambamba_view)
            sambamba_sort = Sort(
                calling_script_path=cfg.get(ConfigConstants.SAMBAMBA, ConfigConstants.SAMBAMBA_PATH),
                output_directory=ap.args.output_directory,
                added_flags=cfg.build_parameter_list_from_dict(ConfigConstants.SAMBAMBA),
                bam_file=sambamba_view.output().path
            )
            task_list.append(sambamba_sort)
            task_list.append(Remove(data_files=[
                single_end.output().path,
                trim_single.output().path,
                os.path.splitext(single_end.output().path)[0] + ".dropB",
                sambamba_view.output().path
            ]))
            task_list.append(GZip(unzipped_file=unzipped_file_and_path))
        line_data = rm.get()
    luigi.build(task_list, local_scheduler=True)
