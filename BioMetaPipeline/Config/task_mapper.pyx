# Contains mappings between name of pipeline and the task classes it contains
from BioMetaPipeline.Annotation.virsorter import VirSorter

pipeline_classes = {
    "virsorter": (VirSorter,),
}
