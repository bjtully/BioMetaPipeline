# cython: language_level=3
import os
import luigi
import shutil
from BioMetaPipeline.Accessories.ops import get_prefix
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.PipelineManagement.project_manager import GENOMES
from BioMetaPipeline.Annotation.biodata import BioData, BioDataConstants
from BioMetaPipeline.Annotation.hmmer import HMMSearch, HMMSearchConstants
from BioMetaPipeline.GeneCaller.prodigal import Prodigal, ProdigalConstants
from BioMetaPipeline.Annotation.kofamscan import KofamScan, KofamScanConstants
from BioMetaPipeline.Annotation.virsorter import VirSorter, VirSorterConstants
from BioMetaPipeline.Database.dbdm_calls import GetDBDMCall, BioMetaDBConstants
from BioMetaPipeline.FileOperations.split_file import SplitFile, SplitFileConstants
from BioMetaPipeline.Annotation.prokka import PROKKA, PROKKAConstants, PROKKAMatcher
from BioMetaPipeline.Annotation.interproscan import Interproscan, InterproscanConstants
from BioMetaPipeline.PipelineManagement.project_manager cimport project_check_and_creation
from BioMetaPipeline.DataPreparation.combine_output import CombineOutput, CombineOutputConstants
from BioMetaPipeline.Alignment.diamond import Diamond, DiamondMakeDB, DiamondConstants, DiamondToFasta

"""
metagenome_annotation consists of:

    Gene Caller
        Prodigal
    Annotation Suites
        Prodigal
        kofamscan
        Interproscan
        PROKKA
        VirSorter
    Parse results
        KEGGDecoder
        BioMetaDB

"""


class MetagenomeAnnotationConstants:
    TABLE_NAME = "Functions"
    TSV_OUT = "metagenome_annotation.tsv"
    LIST_FILE = "metagenome_annotation.list"
    PROJECT_NAME = "MetagenomeAnnotation"


def metagenome_annotation(str directory, str config_file, bint cancel_autocommit, str output_directory,
                          str biometadb_project):
    """ Function calls the pipeline and is run from pipedm

    :param directory:
    :param config_file:
    :param cancel_autocommit:
    :param output_directory:
    :param biometadb_project:
    :return:
    """
    cdef str genome_list_path, alias, table_name, fasta_file, out_prefix
    cdef object cfg
    cdef list constant_classes = [
        ProdigalConstants,
        KofamScanConstants,
        InterproscanConstants,
        PROKKAConstants,
        VirSorterConstants,
        HMMSearchConstants,
        CombineOutputConstants,
        BioDataConstants,
        SplitFileConstants,
        DiamondConstants,
    ]
    genome_list_path, alias, table_name, cfg, biometadb_project = project_check_and_creation(
        <void* >directory,
        <void* >config_file,
        <void* >output_directory,
        biometadb_project,
        <void* >constant_classes,
        MetagenomeAnnotationConstants
    )
    directory = os.path.join(output_directory, GENOMES)
    cdef tuple line_data
    cdef bytes line
    cdef list task_list = []
    cdef object W = open(genome_list_path, "rb")
    cdef object task
    cdef str protein_file = ""
    line = next(W)
    while line:
        fasta_file = line.decode().rstrip("\r\n")
        out_prefix = os.path.splitext(os.path.basename(line.decode().rstrip("\r\n")))[0]
        protein_file = os.path.join(output_directory,
                                        ProdigalConstants.OUTPUT_DIRECTORY,
                                        out_prefix + ProdigalConstants.PROTEIN_FILE_SUFFIX)
        # Build task_list for individual genomes
        for task in (
            Prodigal(
                output_directory=os.path.join(output_directory, ProdigalConstants.OUTPUT_DIRECTORY),
                fasta_file=fasta_file,
                calling_script_path=cfg.get(ProdigalConstants.PRODIGAL, ConfigManager.PATH),
                outfile=out_prefix,
                run_edit=True,
                added_flags=cfg.build_parameter_list_from_dict(ProdigalConstants.PRODIGAL),
            ),
            # For PROKKA adjusting
            DiamondMakeDB(
                output_directory=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY),
                prot_file=protein_file,
                calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
            ),
            # Retrieve sections from contigs matching prodigal gene calls
            Diamond(
                outfile=out_prefix + ".tsv",
                output_directory=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY),
                program="blastx",
                diamond_db=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, get_prefix(protein_file)),
                query_file=fasta_file,
                evalue="1e-10",
                calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
            ),
            DiamondToFasta(
                output_directory=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY),
                outfile=out_prefix + ".subset.fna",
                fasta_file=fasta_file,
                diamond_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".tsv"),
                calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
            ),
            # Split prodigal results for committing to DB
            SplitFile(
                fasta_file=protein_file,
                out_dir=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix),
            ),
            Interproscan(
                calling_script_path=cfg.get(InterproscanConstants.INTERPROSCAN, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, InterproscanConstants.OUTPUT_DIRECTORY),
                fasta_file=protein_file,
                out_prefix=out_prefix,
                added_flags=cfg.build_parameter_list_from_dict(InterproscanConstants.INTERPROSCAN),
                applications=[val for val in cfg.get(InterproscanConstants.INTERPROSCAN, "--applications").split(",") if val != ""],
            ),
            # Commit interproscan results
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=out_prefix,
                alias=out_prefix,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix),
                data_file=os.path.join(
                    output_directory,
                    InterproscanConstants.OUTPUT_DIRECTORY,
                    out_prefix + InterproscanConstants.AMENDED_RESULTS_SUFFIX
                ),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            # Predict KEGG
            KofamScan(
                output_directory=os.path.join(output_directory, KofamScanConstants.OUTPUT_DIRECTORY),
                calling_script_path=cfg.get(KofamScanConstants.KOFAMSCAN, ConfigManager.PATH),
                outfile=out_prefix,
                fasta_file=protein_file,
                added_flags=cfg.build_parameter_list_from_dict(KofamScanConstants.KOFAMSCAN),
            ),
            # Commit kofamscan results
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=out_prefix,
                alias=out_prefix,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix),
                data_file=os.path.join(
                    output_directory,
                    KofamScanConstants.OUTPUT_DIRECTORY,
                    out_prefix + KofamScanConstants.AMENDED_RESULTS_SUFFIX
                ),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            # PROKKA annotation pipeline
            PROKKA(
                calling_script_path=cfg.get(PROKKAConstants.PROKKA, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY),
                out_prefix=out_prefix,
                fasta_file=fasta_file,
                added_flags=cfg.build_parameter_list_from_dict(PROKKAConstants.PROKKA),
            ),
            # For PROKKA adjusting
            DiamondMakeDB(
                output_directory=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY),
                prot_file=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, out_prefix, out_prefix + ".faa"),
                calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
            ),
            # Identify which PROKKA annotations match contigs corresponding to prodigal gene calls and save the subset
            Diamond(
                outfile=out_prefix + ".rev.tsv",
                output_directory=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY),
                program="blastx",
                diamond_db=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix),
                query_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".subset.fna"),
                evalue="1e-20",
                calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
            ),
            # Write final prokka annotations
            PROKKAMatcher(
                output_directory=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY),
                outfile=out_prefix + ".prk-to-prd.tsv",
                diamond_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".rev.tsv"),
                prokka_tsv=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, out_prefix, out_prefix + PROKKAConstants.AMENDED_RESULTS_SUFFIX),
                suffix=".faa",
                evalue="1e-20",
                pident="98.5",
                matches_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".subset.matches"),
                calling_script_path="",
            ),
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=out_prefix,
                alias=out_prefix,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix),
                data_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".prk-to-prd.tsv"),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            # Virsorter annotation pipeline
            VirSorter(
                output_directory=os.path.join(output_directory, VirSorterConstants.OUTPUT_DIRECTORY),
                fasta_file=fasta_file,
                calling_script_path=cfg.get(VirSorterConstants.VIRSORTER, ConfigManager.PATH),
                added_flags=cfg.build_parameter_list_from_dict(VirSorterConstants.VIRSORTER),
                wdir=os.path.abspath(os.path.join(os.path.join(output_directory, VirSorterConstants.OUTPUT_DIRECTORY),
                                  get_prefix(fasta_file))),
            ),
        ):
            task_list.append(task)
        try:
            line = next(W)
        except StopIteration:
            break
    # Combine all results for final parsing
    task_list.append(
        CombineOutput(
            directories=[
                (os.path.join(output_directory, ProdigalConstants.OUTPUT_DIRECTORY), ProdigalConstants.PROTEIN_FILE_SUFFIX,
                 CombineOutputConstants.PROT_OUTPUT_FILE),
                (os.path.join(output_directory, KofamScanConstants.OUTPUT_DIRECTORY), "", CombineOutputConstants.KO_OUTPUT_FILE),
            ],
            calling_script_path="",
            output_directory=os.path.join(output_directory, CombineOutputConstants.OUTPUT_DIRECTORY),
        )
    )
    task_list.append(
        HMMSearch(
            calling_script_path=cfg.get(HMMSearchConstants.HMMSEARCH, ConfigManager.PATH),
            output_directory=os.path.join(output_directory, HMMSearchConstants.OUTPUT_DIRECTORY),
            out_prefix=CombineOutputConstants.HMM_OUTPUT_FILE,
            fasta_file=os.path.join(output_directory, CombineOutputConstants.OUTPUT_DIRECTORY, CombineOutputConstants.PROT_OUTPUT_FILE),
            hmm_file=os.path.join(cfg.get(BioDataConstants.BIODATA, ConfigManager.PATH), BioDataConstants.HMM_PATH)
        )
    )
    task_list.append(
        BioData(
            calling_script_path=cfg.get(BioDataConstants.BIODATA, ConfigManager.PATH),
            output_directory=os.path.join(output_directory, BioDataConstants.OUTPUT_DIRECTORY),
            out_prefix=BioDataConstants.OUTPUT_FILE,
            ko_file=os.path.join(output_directory, CombineOutputConstants.OUTPUT_DIRECTORY, CombineOutputConstants.KO_OUTPUT_FILE),
            hmmsearch_file=os.path.join(output_directory, HMMSearchConstants.OUTPUT_DIRECTORY, CombineOutputConstants.HMM_OUTPUT_FILE),
        )
    )
    task_list.append(
        GetDBDMCall(
            cancel_autocommit=cancel_autocommit,
            table_name=table_name,
            alias=alias,
            calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
            db_name=biometadb_project,
            directory_name=directory,
            data_file=os.path.join(
                output_directory,
                BioDataConstants.OUTPUT_DIRECTORY,
                BioDataConstants.OUTPUT_FILE + BioDataConstants.OUTPUT_SUFFIX,
            ),
            added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
        )
    )
    luigi.build(task_list, local_scheduler=True)
    shutil.rmtree(directory)
    shutil.rmtree(os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY))
