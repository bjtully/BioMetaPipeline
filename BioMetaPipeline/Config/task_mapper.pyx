# Contains mappings between name of pipeline and the task classes it contains
from BioMetaPipeline.Annotation.interproscan import InterproscanConstants
from BioMetaPipeline.Annotation.virsorter import VirSorterConstants

# dict will contain:
#       "pipe_name": ("suffix_of_pipe_output"),
pipeline_classes = {
    "virsorter": (VirSorterConstants.ADJ_OUT_FILE,),
    "interproscan": (InterproscanConstants.AMENDED_RESULTS_SUFFIX,),
    "prokka": (),
}
