#!/usr/bin/env python3

import pysam
from BioMetaPipeline.Accessories.arg_parse import ArgParse
from BioMetaPipeline.Accessories.DataStructures.linked_list import LinkedList


def parse_filter_string(filter_string):
    """ Converts filter_string passed from command line to a dictionary of values

    :param filter_string:
    :return:
    """
    data_string_as_list = LinkedList.split(filter_string, ",")
    filter_dict = {"MAPPING": data_string_as_list[0],
                   "QUAL_MIN": data_string_as_list[1],
                   "PAIRING": data_string_as_list[2]}
    return filter_dict


if __name__ == "__main__":
    args_list = (
        (("-a", "--alignment_file"),
         {"help": ".bam file", }),
        (("-f", "--filter_string"),
         {"help": "MAPPED/UNMAPPED,MAP_QUAL,PAIRED/UNPAIRED | Default: MAPPED,30,UNPAIRED", "default":"MAPPED,30,UNPAIRED"})
    )

    ap = ArgParse(args_list, description="Collected reads matching criteria")
    # bamfile = pysam.AlignmentFile(ap.args.alignment_file, "rb")

