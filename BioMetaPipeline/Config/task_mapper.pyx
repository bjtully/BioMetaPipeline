# Contains mappings between name of pipeline and the task classes it contains
from BioMetaPipeline.Annotation.biodata import BioDataConstants
from BioMetaPipeline.Annotation.interproscan import InterproscanConstants
from BioMetaPipeline.Annotation.prokka import PROKKAConstants
from BioMetaPipeline.Annotation.virsorter import VirSorterConstants

# dict will contain:
#       "pipe_name": ("suffix_of_pipe_output"),
from BioMetaPipeline.Peptidase.cazy import CAZYConstants
from BioMetaPipeline.Peptidase.peptidase import PeptidaseConstants

pipeline_classes = {
    "virsorter": (VirSorterConstants.ADJ_OUT_FILE,),
    "interproscan": (InterproscanConstants.AMENDED_RESULTS_SUFFIX,),
    "prokka": (PROKKAConstants.AMENDED_RESULTS_SUFFIX,),
    "kegg": (BioDataConstants.OUTPUT_SUFFIX,),
    "peptidase": (CAZYConstants.ASSIGNMENTS_BY_PROTEIN, PeptidaseConstants.EXTRACELLULAR_MATCHES_BYPROT_EXT),
}
