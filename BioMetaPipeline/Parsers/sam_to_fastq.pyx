# distutils: language = c++
import os
import pysam


cdef int DEFAULT_LENGTH = 500


cdef void _adjust_criteria_dict(void* criteria_dict):
    cdef object data_keys = (<object>criteria_dict).keys()
    if "LENGTH" not in data_keys:
        (<object>criteria_dict)["LENGTH"] = DEFAULT_LENGTH


cdef void alignment_to_fastq(str alignment_file, dict criteria, str outfile):
    """ Method will convert s/bam to fastq file

    :param outfile:
    :param criteria:
    :param alignment_file:
    :return:
    """
    cdef object W = open(outfile, "w")
    cdef str file_ext = os.path.splitext(alignment_file)[1]
    cdef object alignment_file_object
    cdef object read
    cdef object value
    cdef bint is_read_match
    _adjust_criteria_dict(<void* >criteria)
    cdef int map_qual = int(criteria["MAP_QUAL"])
    cdef int length = int(criteria["LENGTH"])
    if file_ext[1] == "b":
        alignment_file_object = pysam.AlignmentFile(alignment_file, "rb")
    elif file_ext[1] == "s":
        alignment_file_object = pysam.AlignmentFile(alignment_file, "r")
    else:
        raise Exception("File does not have .sam or .bam extension")

    for read in alignment_file_object:
        if getattr(read, "mapping_quality") >= map_qual and \
                len(read.query_sequence) >= length:
            is_read_match = True
            for value in criteria["FLAGS"]:
                if not getattr(read, value):
                    is_read_match = False
                    break
            if is_read_match:
                W.write("@%s\n%s\n+\n%s\n" % (read.query_name,
                                              read.query_sequence,
                                              "".join([chr(x + 33) for x in read.query_qualities])))
    W.close()
