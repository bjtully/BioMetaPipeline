# cython: language_level=3

cdef extern from "Python.h":
    char* PyUnicode_AsUTF8(object unicode)

from libc.stdlib cimport malloc, free

""" 
Functions for manipulating lists of python strings from cython


"""


cdef char** to_cstring_array(list list_of_strings):
    cdef char **ret = <char **>malloc(len(list_of_strings))
    cdef int i
    for i in range(len(list_of_strings)):
        ret[i] = PyUnicode_AsUTF8(list_of_strings[i])
    return ret


cdef clear_cstring_array(char** cstring_array):
    free(cstring_array)
    return None


cdef list to_py_list(char** cstring_array, int length):
    return [str(cstring_array[i]) for i in range(length)]


cdef char* to_cstring(str py_string):
    cdef char *pystr = PyUnicode_AsUTF8(py_string)
    return pystr

cdef free_cstring(char* cstring):
    free(cstring)
    return None
