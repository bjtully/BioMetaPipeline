# distutils: language = c++
# cython: language_level=3
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
    cdef bint is_bam = False
    cdef str file_ext = os.path.splitext(alignment_file)[1]
    cdef object alignment_file_object
    cdef object read
    cdef object value
    cdef bint is_read_match
    _adjust_criteria_dict(<void* >criteria)
    if file_ext[1] == "b":
        is_bam = True
    elif file_ext[1] == "s":
        is_bam = False
    else:
        is_bam = None
    assert is_bam is not None, "File does not have .sam or .bam extension"
    if is_bam:
        alignment_file_object = pysam.AlignmentFile(alignment_file, "rb")
    else:
        alignment_file_object = pysam.AlignmentFile(alignment_file, "r")

    for read in alignment_file_object:
        is_read_match = True
        if int(getattr(read, "mapping_quality")) >= int(criteria["MAP_QUAL"]) and \
                len(read.query_sequence) >= int(criteria["LENGTH"]):
            for value in criteria["FLAGS"]:
                if not getattr(read, value):
                    is_read_match = False
                    break
            if is_read_match:
                W.write("@%s\n%s\n+\n%s\n" % (read.query_name,
                                              read.query_sequence,
                                              "".join([chr(x + 33) for x in read.query_qualities])))
    W.close()
