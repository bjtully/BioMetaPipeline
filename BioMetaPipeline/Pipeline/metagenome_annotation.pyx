# cython: language_level=3
import os
import luigi
import shutil
from BioMetaPipeline.Accessories.ops import get_prefix
from BioMetaPipeline.Parsers.tsv_parser import TSVParser
from BioMetaPipeline.Peptidase.cazy import CAZY, CAZYConstants
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.Peptidase.psortb import PSORTb, PSORTbConstants
from BioMetaPipeline.PipelineManagement.project_manager import GENOMES
from BioMetaPipeline.Peptidase.signalp import SignalP, SignalPConstants
from BioMetaPipeline.Annotation.biodata import BioData, BioDataConstants
from BioMetaPipeline.GeneCaller.prodigal import Prodigal, ProdigalConstants
from BioMetaPipeline.Peptidase.peptidase import Peptidase, PeptidaseConstants
from BioMetaPipeline.Annotation.kofamscan import KofamScan, KofamScanConstants
from BioMetaPipeline.Annotation.virsorter import VirSorter, VirSorterConstants
from BioMetaPipeline.Database.dbdm_calls import GetDBDMCall, BioMetaDBConstants
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


def metagenome_annotation(str directory, str config_file, bint cancel_autocommit, str output_directory,
                          str biometadb_project, str type_file):
    """ Function calls the pipeline and is run from pipedm

    :param directory:
    :param config_file:
    :param cancel_autocommit:
    :param output_directory:
    :param biometadb_project:
    :param type_file:
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
        CAZYConstants,
        PeptidaseConstants,
        HMMConvertConstants,
        MEROPSConstants,
        SignalPConstants,
        PSORTbConstants,
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
    cdef object R = open(genome_list_path, "rb")
    cdef object task
    cdef str protein_file = ""
    # Used for signalp and psortb processing
    cdef dict bact_arch_type = TSVParser.parse_dict(type_file)
    # For merops conversion
    cdef dict merops_dict = build_merops_dict(cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA_DICT))
    # Prepare CAZy hmm profiles
    task_list.append(
        HMMConvert(
            output_directory=os.path.join(output_directory, HMMConvertConstants.OUTPUT_DIRECTORY),
            hmm_file=cfg.get(CAZYConstants.CAZY, ConfigManager.DATA),
            calling_script_path=cfg.get(HMMConvertConstants.HMMCONVERT, ConfigManager.PATH),
        ),
    )
    task_list.append(
        HMMPress(
            output_directory=os.path.join(output_directory, HMMConvertConstants.OUTPUT_DIRECTORY),
            hmm_file=cfg.get(CAZYConstants.CAZY, ConfigManager.DATA),
            calling_script_path=cfg.get(HMMPressConstants.HMMPRESS, ConfigManager.PATH),
        ),
    )
    # Prepare MEROPS hmm profiles
    task_list.append(
        HMMConvert(
            output_directory=os.path.join(output_directory, HMMConvertConstants.OUTPUT_DIRECTORY),
            hmm_file=cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA),
            calling_script_path=cfg.get(HMMConvertConstants.HMMCONVERT, ConfigManager.PATH),
        ),
    )
    task_list.append(
        HMMPress(
            output_directory=os.path.join(output_directory, HMMConvertConstants.OUTPUT_DIRECTORY),
            hmm_file=cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA),
            calling_script_path=cfg.get(HMMPressConstants.HMMPRESS, ConfigManager.PATH),
        ),
    )
    line = next(R)
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
            # Split genome for committing virsorter results to db
            SplitFile(
                fasta_file=fasta_file,
                out_dir=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix + ".fna"),
            ),
            # Store virsorter info to database
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=out_prefix,
                alias=out_prefix,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix + ".fna"),
                data_file=os.path.abspath(os.path.join(os.path.join(output_directory, VirSorterConstants.OUTPUT_DIRECTORY),
                                  get_prefix(fasta_file), "virsorter-out", VirSorterConstants.ADJ_OUT_FILE)),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            # Begin peptidase portion of pipeline
            # Search for CAZy
            HMMSearch(
                calling_script_path=cfg.get(HMMSearchConstants.HMMSEARCH, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, HMMSearchConstants.OUTPUT_DIRECTORY),
                out_file=out_prefix + "." + CAZYConstants.HMM_FILE,
                fasta_file=protein_file,
                hmm_file=os.path.join(output_directory, HMMConvertConstants.OUTPUT_DIRECTORY, cfg.get(CAZYConstants.CAZY, ConfigManager.DATA)),
            ),
            # Assign CAZy info for genome
            CAZY(
                hmm_results=os.path.join(output_directory, HMMSearchConstants.OUTPUT_DIRECTORY, out_prefix + "." + CAZYConstants.HMM_FILE),
                output_directory=os.path.join(output_directory, CAZYConstants.OUTPUT_DIRECTORY),
                outfile=out_prefix + "." + CAZYConstants.ASSIGNMENTS,
                calling_script_path="",
                prot_suffix=os.path.splitext(ProdigalConstants.PROTEIN_FILE_SUFFIX)[1],
                genome_basename=os.path.basename(fasta_file),
            ),
            # Store CAZy output in peptidase-specific database
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=out_prefix + MetagenomeAnnotationConstants.PEPTIDASE,
                alias=out_prefix + MetagenomeAnnotationConstants.PEPTIDASE,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix),
                data_file=os.path.join(output_directory, CAZYConstants.OUTPUT_DIRECTORY, out_prefix + "." + CAZYConstants.ASSIGNMENTS_BY_PROTEIN),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            # Store CAZy count info
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=table_name,
                alias=alias,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=directory,
                data_file=os.path.join(output_directory, CAZYConstants.OUTPUT_DIRECTORY, out_prefix + "." + CAZYConstants.ASSIGNMENTS),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            # Search for MEROPS
            HMMSearch(
                calling_script_path=cfg.get(HMMSearchConstants.HMMSEARCH, ConfigManager.PATH),
                output_directory=os.path.join(output_directory, HMMSearchConstants.OUTPUT_DIRECTORY),
                out_file=out_prefix + "." + MEROPSConstants.HMM_FILE,
                fasta_file=protein_file,
                hmm_file=os.path.join(output_directory, HMMConvertConstants.OUTPUT_DIRECTORY, cfg.get(MEROPSConstants.MEROPS, ConfigManager.DATA)),
            ),
            # Assign MEROPS info for genome
            MEROPS(
                calling_script_path="",
                hmm_results=os.path.join(output_directory, HMMSearchConstants.OUTPUT_DIRECTORY, out_prefix + "." + MEROPSConstants.HMM_FILE),
                output_directory=os.path.join(output_directory, MEROPSConstants.OUTPUT_DIRECTORY),
                outfile=out_prefix + "." + MEROPSConstants.MEROPS_PROTEIN_FILE_SUFFIX,
                prot_file=protein_file,
            ),
            # Run signalp
            SignalP(
                calling_script_path=cfg.get(SignalPConstants.SIGNALP, ConfigManager.PATH),
                membrane_type=bact_arch_type[os.path.basename(fasta_file)][1],
                output_directory=os.path.join(output_directory, SignalPConstants.OUTPUT_DIRECTORY),
                outfile=out_prefix + SignalPConstants.RESULTS_SUFFIX,
                prot_file=protein_file,
            ),
            # Run psortb
            PSORTb(
                data_type=bact_arch_type[os.path.basename(fasta_file)][1],
                domain_type=bact_arch_type[os.path.basename(fasta_file)][0],
                prot_file=protein_file,
                output_directory=os.path.join(output_directory, PSORTbConstants.OUTPUT_DIRECTORY, out_prefix),
                calling_script_path=cfg.get(PSORTbConstants.PSORTB, ConfigManager.PATH),
            ),
            # Parse signalp and psortb through merops to identify peptidases
            Peptidase(
                calling_script_path="",
                psortb_results=os.path.join(output_directory, PSORTbConstants.OUTPUT_DIRECTORY, get_prefix(protein_file) + ".tbl"),
                signalp_results=os.path.join(output_directory, SignalPConstants.OUTPUT_DIRECTORY, out_prefix + SignalPConstants.RESULTS_SUFFIX),
                merops_hmm_results=os.path.join(output_directory, HMMSearchConstants.OUTPUT_DIRECTORY, out_prefix + "." + MEROPSConstants.HMM_FILE),
                output_directory=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY),
                output_prefix=out_prefix,
                protein_suffix=os.path.splitext(ProdigalConstants.PROTEIN_FILE_SUFFIX)[1],
                genome_id_and_ext=os.path.basename(fasta_file),
                pfam_to_merops_dict=merops_dict,
            ),
            # Commit protein-specific info to database
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=out_prefix + MetagenomeAnnotationConstants.PEPTIDASE,
                alias=out_prefix + MetagenomeAnnotationConstants.PEPTIDASE,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=os.path.join(output_directory, SplitFileConstants.OUTPUT_DIRECTORY, out_prefix),
                data_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, PeptidaseConstants.EXTRACELLULAR_MATCHES_BYPROT_EXT),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            # Commit genome-wide info to database
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=table_name,
                alias=alias,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=directory,
                data_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, out_prefix + PeptidaseConstants.MEROPS_HITS_EXT),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
            GetDBDMCall(
                cancel_autocommit=cancel_autocommit,
                table_name=table_name,
                alias=alias,
                calling_script_path=cfg.get(BioMetaDBConstants.BIOMETADB, ConfigManager.PATH),
                db_name=biometadb_project,
                directory_name=directory,
                data_file=os.path.join(output_directory, PeptidaseConstants.OUTPUT_DIRECTORY, out_prefix + PeptidaseConstants.EXTRACELLULAR_MATCHES_EXT),
                added_flags=cfg.get_added_flags(BioMetaDBConstants.BIOMETADB),
            ),
        ):
            task_list.append(task)
        try:
            line = next(R)
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
            out_file=CombineOutputConstants.HMM_OUTPUT_FILE,
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
