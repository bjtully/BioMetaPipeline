cdef class Node:
    cdef void* value
    cdef Node next_node


cdef class LinkedList:
    cdef int length
    cdef Node node
    cdef Node initial
