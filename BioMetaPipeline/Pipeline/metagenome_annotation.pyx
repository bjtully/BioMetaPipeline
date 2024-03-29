# cython: language_level=3
import os
import glob
import luigi
import shutil
from BioMetaPipeline.Accessories.ops import get_prefix
from BioMetaPipeline.Parsers.tsv_parser import TSVParser
from BioMetaPipeline.Peptidase.cazy import CAZY, CAZYConstants
from BioMetaPipeline.PipelineManagement.print_id import PrintID
from BioMetaPipeline.Peptidase.psortb import PSORTb, PSORTbConstants
from BioMetaPipeline.PipelineManagement.project_manager import GENOMES
from BioMetaPipeline.FileOperations.file_operations import Remove, Move
from BioMetaPipeline.Peptidase.signalp import SignalP, SignalPConstants
from BioMetaPipeline.Annotation.biodata import BioData, BioDataConstants
from BioMetaPipeline.GeneCaller.prodigal import Prodigal, ProdigalConstants
from BioMetaPipeline.Peptidase.peptidase import Peptidase, PeptidaseConstants
from BioMetaPipeline.Annotation.kofamscan import KofamScan, KofamScanConstants
from BioMetaPipeline.Annotation.virsorter import VirSorter, VirSorterConstants
from BioMetaPipeline.Database.dbdm_calls import GetDBDMCall, BioMetaDBConstants
from BioMetaPipeline.Config.config_manager import ConfigManager, pipeline_classes
from BioMetaPipeline.FileOperations.split_file import SplitFile, SplitFileConstants
from BioMetaPipeline.Annotation.prokka import PROKKA, PROKKAConstants, PROKKAMatcher
from BioMetaPipeline.Annotation.interproscan import Interproscan, InterproscanConstants
from BioMetaPipeline.Peptidase.merops import MEROPS, MEROPSConstants, build_merops_dict
from BioMetaPipeline.PipelineManagement.project_manager cimport project_check_and_creation
from BioMetaPipeline.DataPreparation.combine_output import CombineOutput, CombineOutputConstants
from BioMetaPipeline.Alignment.diamond import Diamond, DiamondMakeDB, DiamondConstants, DiamondToFasta
from BioMetaPipeline.Annotation.hmmer import HMMSearch, HMMSearchConstants, HMMConvert, HMMPress, HMMConvertConstants, HMMPressConstants

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
    PEPTIDASE = "_peptidase"
    PIPELINE_NAME = "metagenome_annotation"
    STORAGE_STRING = "Combined results"


def metagenome_annotation(str directory, str config_file, bint cancel_autocommit, str output_directory,
                          str biometadb_project, str type_file, bint is_docker, bint remove_intermediates):
    """ Function calls the pipeline and is run from pipedm

    :param directory:
    :param config_file:
    :param cancel_autocommit:
    :param output_directory:
    :param biometadb_project:
    :param type_file:
    :param is_docker:
    :param remove_intermediates:
    :return:
    """
    cdef str genome_list_path, alias, table_name, fasta_file, out_prefix, _file, prefix
    cdef object cfg
    genome_list_path, alias, table_name, cfg, biometadb_project = project_check_and_creation(
        <void* >directory,
        <void* >config_file,
        <void* >output_directory,
        biometadb_project,
        MetagenomeAnnotationConstants,
    )
    directory = os.path.join(output_directory, GENOMES)
    cdef tuple line_data
    cdef bytes line
    cdef list task_list = [], out_prefixes = []
    cdef object R = open(genome_list_path, "rb")
    cdef object task
    cdef str protein_file = ""
    # Used for signalp and psortb processing
    cdef dict bact_arch_type = {}
    # For merops conversion
    cdef dict merops_dict
    if type_file != "None":
            bact_arch_type = {os.path.splitext(key.replace("_", "-"))[0] + ".fna": val
                              for key, val in TSVParser.parse_dict(type_file).items()}

    # Prepare CAZy hmm profiles if set in config
    if cfg.check_pipe_set("peptidase", MetagenomeAnnotationConstants.PIPELINE_NAME):
        task_list.append(
            HMMConvert(
                output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY,
                                              CAZYConstants.OUTPUT_DIRECTORY, HMMConvertConstants.OUTPUT_DIRECTORY),
                hmm_file=cfg.get(CAZYConstants.CAZY, ConfigManager.DATA),
                calling_script_path=cfg.get(HMMConvertConstants.HMMCONVERT, ConfigManager.PATH),
                added_flags=cfg.build_parameter_list_from_dict(HMMConvertConstants.HMMCONVERT),
            ),
        )
        task_list.append(
            HMMPress(
                output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY,
                                              CAZYConstants.OUTPUT_DIRECTORY, HMMConvertConstants.OUTPUT_DIRECTORY),
                hmm_file=cfg.get(CAZYConstants.CAZY, ConfigManager.DATA),
                calling_script_path=cfg.get(HMMPressConstants.HMMPRESS, ConfigManager.PATH),
                added_flags=cfg.build_parameter_list_from_dict(HMMPressConstants.HMMPRESS),
            ),
        )
        # Prepare MEROPS hmm profiles
        task_list.append(
            HMMConvert(
                output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY,
                                              MEROPSConstants.OUTPUT_DIRECTORY, HMMConvertConstants.OUTPUT_DIRECTORY),
                hmm_file=cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA),
                calling_script_path=cfg.get(HMMConvertConstants.HMMCONVERT, ConfigManager.PATH),
                added_flags=cfg.build_parameter_list_from_dict(HMMConvertConstants.HMMCONVERT),
            ),
        )
        task_list.append(
            HMMPress(
                output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY,
                                              MEROPSConstants.OUTPUT_DIRECTORY, HMMConvertConstants.OUTPUT_DIRECTORY),
                hmm_file=cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA),
                calling_script_path=cfg.get(HMMPressConstants.HMMPRESS, ConfigManager.PATH),
                added_flags=cfg.build_parameter_list_from_dict(HMMPressConstants.HMMPRESS),
            ),
        )

    line = next(R)
    while line:
        fasta_file = line.decode().rstrip("\r\n")
        out_prefix = os.path.splitext(os.path.basename(line.decode().rstrip("\r\n")))[0]
        out_prefixes.append(out_prefix)
        protein_file = os.path.join(output_directory,
                                        ProdigalConstants.OUTPUT_DIRECTORY,
                                        out_prefix + ProdigalConstants.PROTEIN_FILE_SUFFIX)

        # Print task id for user
        task_list.append(
            PrintID(
                out_prefix=out_prefix,
            )
        )

        # Required task - predict proteins in contigs
        task_list.append(
            Prodigal(
                output_directory=os.path.join(output_directory, ProdigalConstants.OUTPUT_DIRECTORY),
                fasta_file=fasta_file,
                calling_script_path=cfg.get(ProdigalConstants.PRODIGAL, ConfigManager.PATH),
                outfile=out_prefix,
                run_edit=True,
                added_flags=cfg.build_parameter_list_from_dict(ProdigalConstants.PRODIGAL),
            ),
        )
        # Required task - split protein file into separate fasta files
        task_list.append(
            SplitFile(
                fasta_file=protein_file,
                out_dir=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix),
            ),
        )
        # Required task - split genomes file into separate fasta files
        task_list.append(
            SplitFile(
                fasta_file=fasta_file,
                out_dir=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix + ".fna"),
            ),
        )
        # Required task - extract sections of contigs corresponding to prodigal gene calls
        for task in (
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
                added_flags=cfg.build_parameter_list_from_dict(DiamondConstants.DIAMOND),
            ),
            DiamondToFasta(
                output_directory=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY),
                outfile=out_prefix + ".subset.fna",
                fasta_file=fasta_file,
                diamond_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".tsv"),
                calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
            ),
        ):
            task_list.append(task)

        # Optional task - virsorter
        if cfg.check_pipe_set("virsorter", MetagenomeAnnotationConstants.PIPELINE_NAME):
            for task in (
                # Virsorter annotation pipeline
                VirSorter(
                    output_directory=os.path.join(output_directory, VirSorterConstants.OUTPUT_DIRECTORY),
                    fasta_file=fasta_file,
                    calling_script_path=cfg.get(VirSorterConstants.VIRSORTER, ConfigManager.PATH),
                    added_flags=cfg.build_parameter_list_from_dict(VirSorterConstants.VIRSORTER),
                    wdir=os.path.abspath(os.path.join(output_directory, VirSorterConstants.OUTPUT_DIRECTORY, get_prefix(fasta_file))),
                    is_docker=is_docker,
                ),
                # Store virsorter info to database
                GetDBDMCall(
                    cancel_autocommit=cancel_autocommit,
                    table_name=out_prefix,
                    alias=out_prefix,
                    calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                    db_name=biometadb_project,
                    directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix + ".fna"),
                    data_file=os.path.join(output_directory, VirSorterConstants.OUTPUT_DIRECTORY, get_prefix(fasta_file),
                                           "virsorter-out", out_prefix + "." + VirSorterConstants.ADJ_OUT_FILE),
                    added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
                    storage_string=out_prefix + " " + VirSorterConstants.STORAGE_STRING,
                ),
            ):
                task_list.append(task)

        # Optional task - kegg
        if cfg.check_pipe_set("kegg", MetagenomeAnnotationConstants.PIPELINE_NAME):
            for task in (
                # Predict KEGG
                KofamScan(
                    output_directory=os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, KofamScanConstants.OUTPUT_DIRECTORY),
                    calling_script_path=cfg.get(KofamScanConstants.KOFAMSCAN, ConfigManager.PATH),
                    outfile=out_prefix,
                    fasta_file=protein_file,
                    added_flags=cfg.build_parameter_list_from_dict(KofamScanConstants.KOFAMSCAN),
                ),
            ):
                task_list.append(task)
        # Optional task - prokka
        if cfg.check_pipe_set("prokka", MetagenomeAnnotationConstants.PIPELINE_NAME):
            for task in (
                # PROKKA annotation pipeline
                PROKKA(
                    calling_script_path=cfg.get(PROKKAConstants.PROKKA, ConfigManager.PATH),
                    output_directory=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY),
                    out_prefix=out_prefix,
                    fasta_file=fasta_file,
                    added_flags=cfg.build_parameter_list_from_dict(PROKKAConstants.PROKKA),
                    domain_type=(bact_arch_type.get(os.path.basename(fasta_file), (PeptidaseConstants.BACTERIA,))[0] if bact_arch_type else PeptidaseConstants.BACTERIA)
                ),
                # For PROKKA adjusting
                DiamondMakeDB(
                    output_directory=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, DiamondConstants.OUTPUT_DIRECTORY),
                    prot_file=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, out_prefix, out_prefix + ".faa"),
                    calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
                ),
                # Identify which PROKKA annotations match contigs corresponding to prodigal gene calls and save the subset
                Diamond(
                    outfile=out_prefix + ".rev.tsv",
                    output_directory=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, DiamondConstants.OUTPUT_DIRECTORY),
                    program="blastx",
                    diamond_db=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, DiamondConstants.OUTPUT_DIRECTORY, out_prefix),
                    query_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".subset.fna"),
                    evalue="1e-20",
                    calling_script_path=cfg.get(DiamondConstants.DIAMOND, ConfigManager.PATH),
                    added_flags=cfg.build_parameter_list_from_dict(DiamondConstants.DIAMOND),
                ),
                # Write final prokka annotations
                PROKKAMatcher(
                    output_directory=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, DiamondConstants.OUTPUT_DIRECTORY),
                    outfile=out_prefix + ".prk-to-prd.tsv",
                    diamond_file=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY,
                                              DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".rev.tsv"),
                    prokka_tsv=os.path.join(output_directory, PROKKAConstants.OUTPUT_DIRECTORY, out_prefix,
                                            out_prefix + PROKKAConstants.AMENDED_RESULTS_SUFFIX),
                    suffix=".faa",
                    evalue="1e-20",
                    pident="98.5",
                    matches_file=os.path.join(output_directory, DiamondConstants.OUTPUT_DIRECTORY, out_prefix + ".subset.matches"),
                    calling_script_path="",
                ),
            ):
                task_list.append(task)

        # Optional task - interproscan
        if cfg.check_pipe_set("interproscan", MetagenomeAnnotationConstants.PIPELINE_NAME):
            for task in (
                Interproscan(
                    calling_script_path=cfg.get(InterproscanConstants.INTERPROSCAN, ConfigManager.PATH),
                    output_directory=os.path.join(output_directory, InterproscanConstants.OUTPUT_DIRECTORY),
                    fasta_file=protein_file,
                    out_prefix=out_prefix,
                    added_flags=cfg.build_parameter_list_from_dict(InterproscanConstants.INTERPROSCAN),
                    applications=[val for val in cfg.get(InterproscanConstants.INTERPROSCAN, "--applications").split(",") if val != ""],
                ),
            ):
                task_list.append(task)

        # Optional task - peptidase
        if cfg.check_pipe_set("peptidase", MetagenomeAnnotationConstants.PIPELINE_NAME):
            merops_dict = build_merops_dict(cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA_DICT))
            for task in (
                # Begin peptidase portion of pipeline
                # Search for CAZy
                HMMSearch(
                    added_flags=cfg.build_parameter_list_from_dict(HMMSearchConstants.HMMSEARCH),
                    calling_script_path=cfg.get(HMMSearchConstants.HMMSEARCH, ConfigManager.PATH),
                    output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, CAZYConstants.OUTPUT_DIRECTORY,
                                                  HMMSearchConstants.OUTPUT_DIRECTORY),
                    out_file=out_prefix + "." + CAZYConstants.HMM_FILE,
                    fasta_file=protein_file,
                    hmm_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, CAZYConstants.OUTPUT_DIRECTORY,
                                          HMMConvertConstants.OUTPUT_DIRECTORY, cfg.get(CAZYConstants.CAZY, ConfigManager.DATA))

                ),
                # Assign CAZy info for genomes
                CAZY(
                    hmm_results=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, CAZYConstants.OUTPUT_DIRECTORY,
                                             HMMSearchConstants.OUTPUT_DIRECTORY, out_prefix + "." + CAZYConstants.HMM_FILE),
                    output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, CAZYConstants.OUTPUT_DIRECTORY),
                    outfile=out_prefix + "." + CAZYConstants.ASSIGNMENTS,
                    calling_script_path="",
                    prot_suffix=os.path.splitext(ProdigalConstants.PROTEIN_FILE_SUFFIX)[1],
                    genome_basename=os.path.basename(fasta_file),
                ),
                # Search for MEROPS
                HMMSearch(
                    added_flags=cfg.build_parameter_list_from_dict(HMMSearchConstants.HMMSEARCH),
                    calling_script_path=cfg.get(HMMSearchConstants.HMMSEARCH, ConfigManager.PATH),
                    output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, MEROPSConstants.OUTPUT_DIRECTORY,
                                                  HMMSearchConstants.OUTPUT_DIRECTORY),
                    out_file=out_prefix + "." + MEROPSConstants.HMM_FILE,
                    fasta_file=protein_file,
                    hmm_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, MEROPSConstants.OUTPUT_DIRECTORY,
                                          HMMConvertConstants.OUTPUT_DIRECTORY, cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA)),
                ),
                # Assign MEROPS info for genomes
                MEROPS(
                    calling_script_path="",
                    hmm_results=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, MEROPSConstants.OUTPUT_DIRECTORY,
                                             HMMSearchConstants.OUTPUT_DIRECTORY, out_prefix + "." + MEROPSConstants.HMM_FILE),
                    output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, MEROPSConstants.OUTPUT_DIRECTORY),
                    outfile=out_prefix + "." + MEROPSConstants.MEROPS_PROTEIN_FILE_SUFFIX,
                    prot_file=protein_file,
                ),
                # Run signalp
                SignalP(
                    calling_script_path=cfg.get(SignalPConstants.SIGNALP, ConfigManager.PATH),
                    membrane_type=(bact_arch_type.get(os.path.basename(fasta_file), (0, PeptidaseConstants.GRAM_NEG))[1] if bact_arch_type else PeptidaseConstants.GRAM_NEG),
                    output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, SignalPConstants.OUTPUT_DIRECTORY),
                    outfile=out_prefix + SignalPConstants.RESULTS_SUFFIX,
                    prot_file=protein_file,
                    added_flags=cfg.build_parameter_list_from_dict(SignalPConstants.SIGNALP),
                ),
                # Run psortb
                PSORTb(
                    data_type=(bact_arch_type.get(os.path.basename(fasta_file), (0, PeptidaseConstants.GRAM_NEG))[1] if bact_arch_type else PeptidaseConstants.GRAM_NEG),
                    domain_type=(bact_arch_type.get(os.path.basename(fasta_file), (PeptidaseConstants.BACTERIA,))[0] if bact_arch_type else PeptidaseConstants.BACTERIA),
                    prot_file=protein_file,
                    output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, PSORTbConstants.OUTPUT_DIRECTORY, out_prefix),
                    calling_script_path=cfg.get(PSORTbConstants.PSORTB, ConfigManager.PATH),
                    is_docker=is_docker,
                    added_flags=cfg.build_parameter_list_from_dict(PSORTbConstants.PSORTB),
                ),
                # Parse signalp and psortb through merops to identify peptidases
                Peptidase(
                    calling_script_path="",
                    psortb_results=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, PSORTbConstants.OUTPUT_DIRECTORY,
                                                get_prefix(protein_file) + ".tbl"),
                    signalp_results=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, SignalPConstants.OUTPUT_DIRECTORY,
                                                 out_prefix + SignalPConstants.RESULTS_SUFFIX),
                    merops_hmm_results=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, MEROPSConstants.OUTPUT_DIRECTORY,
                                                    HMMSearchConstants.OUTPUT_DIRECTORY, out_prefix + "." + MEROPSConstants.HMM_FILE),
                    output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY),
                    output_prefix=out_prefix,
                    protein_suffix=os.path.splitext(ProdigalConstants.PROTEIN_FILE_SUFFIX)[1],
                    genome_id_and_ext=os.path.basename(fasta_file),
                    pfam_to_merops_dict=merops_dict,
                ),
            ):
                task_list.append(task)
        try:
            line = next(R)
        except StopIteration:
            break
    R.close()
    # Optional task - Peptidase
    # Combine all results and commit to database
    if cfg.check_pipe_set("peptidase", MetagenomeAnnotationConstants.PIPELINE_NAME):
        # Combine all genomes count results
        task_list.append(
            CombineOutput(
                directories=[
                    # All CAZy summary results
                    (os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, CAZYConstants.OUTPUT_DIRECTORY),
                     (),
                     (CAZYConstants.ASSIGNMENTS,),
                     CombineOutputConstants.CAZY_OUTPUT_FILE),
                    # All MEROPS by MEROPS summary results
                    (os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY),
                     (),
                     (PeptidaseConstants.MEROPS_HITS_EXT,),
                     CombineOutputConstants.MEROPS_OUTPUT_FILE),
                    # All MEROPS by PFAM summary results
                    (os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY),
                     (),
                     (PeptidaseConstants.EXTRACELLULAR_MATCHES_EXT,),
                     CombineOutputConstants.MEROPS_PFAM_OUTPUT_FILE),
                ],
                calling_script_path="",
                output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, CombineOutputConstants.OUTPUT_DIRECTORY),
                join_header=True,
                delimiter="\t",
            )
        )
        # Store CAZy count info
        task_list.append(
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=table_name,
                alias=alias,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=directory,
                data_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY,
                                       CombineOutputConstants.OUTPUT_DIRECTORY, CombineOutputConstants.CAZY_OUTPUT_FILE),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
                storage_string=CAZYConstants.SUMMARY_STORAGE_STRING,
            )
        )
        task_list.append(
            # MEROPS matches by their PFAM id
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=table_name,
                alias=alias,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=directory,
                data_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY,
                                       CombineOutputConstants.OUTPUT_DIRECTORY, CombineOutputConstants.MEROPS_PFAM_OUTPUT_FILE),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
                storage_string=MEROPSConstants.STORAGE_STRING,
            ),
        )
        task_list.append(
            # MEROPS matches by their MEROPS id
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=table_name,
                alias=alias,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=directory,
                data_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY,
                                       CombineOutputConstants.OUTPUT_DIRECTORY, CombineOutputConstants.MEROPS_OUTPUT_FILE),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
                storage_string=MEROPSConstants.SUMMARY_STORAGE_STRING,
            ),
        )

    # Optional task - kegg
    # Combine all results for final parsing
    if cfg.check_pipe_set("kegg", MetagenomeAnnotationConstants.PIPELINE_NAME):
        # Combine folders with entire output to single directory
        task_list.append(
            CombineOutput(
                directories=[
                    # All prodigal proteins
                    (os.path.join(output_directory, ProdigalConstants.OUTPUT_DIRECTORY),
                     (),
                     (ProdigalConstants.PROTEIN_FILE_SUFFIX,),
                     CombineOutputConstants.PROT_OUTPUT_FILE),
                    # All kofamscan default results (e.g. non-amended, which was for genomes-specific and not cumulative)
                    (os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, KofamScanConstants.OUTPUT_DIRECTORY),
                     (),
                     (".tsv",),
                     CombineOutputConstants.KO_OUTPUT_FILE),
                ],
                calling_script_path="",
                output_directory=os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, CombineOutputConstants.OUTPUT_DIRECTORY),
            )
        )
        task_list.append(
            HMMSearch(
                calling_script_path=cfg.get(HMMSearchConstants.HMMSEARCH, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, HMMSearchConstants.OUTPUT_DIRECTORY),
                out_file=CombineOutputConstants.HMM_OUTPUT_FILE,
                fasta_file=os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, CombineOutputConstants.OUTPUT_DIRECTORY,
                                        CombineOutputConstants.PROT_OUTPUT_FILE),
                hmm_file=os.path.join(cfg.get(BioDataConstants.BIODATA, ConfigManager.PATH), BioDataConstants.HMM_PATH),
                added_flags=cfg.build_parameter_list_from_dict(HMMSearchConstants.HMMSEARCH),
            )
        )
        task_list.append(
            BioData(
                calling_script_path=cfg.get(BioDataConstants.BIODATA, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, BioDataConstants.OUTPUT_DIRECTORY),
                out_prefix=BioDataConstants.OUTPUT_FILE,
                ko_file=os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, CombineOutputConstants.OUTPUT_DIRECTORY,
                                     CombineOutputConstants.KO_OUTPUT_FILE),
                hmmsearch_file=os.path.join(output_directory, KofamScanConstants.KEGG_DIRECTORY, HMMSearchConstants.OUTPUT_DIRECTORY,
                                            CombineOutputConstants.HMM_OUTPUT_FILE),
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
                    KofamScanConstants.KEGG_DIRECTORY,
                    BioDataConstants.OUTPUT_DIRECTORY,
                    BioDataConstants.OUTPUT_FILE + BioDataConstants.OUTPUT_SUFFIX,
                ),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
                storage_string=BioDataConstants.STORAGE_STRING,
            )
        )

    # Final task - combine all results from annotation into single tsv file per genomes
    if cfg.completed_tests:
        for prefix in out_prefixes:
            task_list.append(
                CombineOutput(
                    directories=[
                        # All annotation results
                        (os.path.join(output_directory),
                        # By genomes
                        (prefix,),
                        # All possible suffixes
                        tuple(_v for key, val in pipeline_classes.items() for _v in val if key in cfg.completed_tests and key != "virsorter"),
                        prefix + "." + MetagenomeAnnotationConstants.TSV_OUT),
                    ],
                    calling_script_path="",
                    output_directory=os.path.join(output_directory),
                    na_rep="None",
                    join_header=True,
                )
            )
            # Store combined data to database
            task_list.append(
                GetDBDMCall(
                    cancel_autocommit=cancel_autocommit,
                    table_name=prefix,
                    alias=prefix,
                    calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                    db_name=biometadb_project,
                    directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, prefix),
                    data_file=os.path.join(output_directory, prefix + "." + MetagenomeAnnotationConstants.TSV_OUT),
                    added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
                    storage_string=prefix + " " + MetagenomeAnnotationConstants.STORAGE_STRING,
                )
            )

        # # Remove combined output
        # task_list.append(
        #     Remove(
        #         data_folder=os.path.join(
        #             output_directory,
        #             KofamScanConstants.KEGG_DIRECTORY,
        #             CombineOutputConstants.OUTPUT_DIRECTORY
        #         )
        #     )
        # )
        # # Move the .svg output to output directory
        # task_list.append(
        #     Move(
        #         move_directory=os.path.join(output_directory, BioDataConstants.OUTPUT_DIRECTORY),
        #         data_files=list(glob.glob("*.svg")),
        #     )
        # )
    luigi.build(task_list, local_scheduler=True)
    cfg.citation_generator.write(os.path.join(output_directory, "citations.txt"))
    # Remove directories that were added as part of the pipeline
    if remove_intermediates:
        shutil.rmtree(directory)
        shutil.rmtree(os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY))
    print("MET_ANNOT pipeline complete!")
