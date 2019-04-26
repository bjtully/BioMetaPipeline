import os
from configparser import NoOptionError
from BioMetaPipeline.Pipeline.Exceptions.GeneralAssertion import AssertString
from BioMetaPipeline.Config.config_manager import ConfigManager
from BioMetaPipeline.Database.dbdm_calls import BioMetaDBConstants


cdef str OUTPUT_DIRECTORY = "OUTPUT_DIRECTORY"
cdef str LIST_FILE = "LIST_FILE"
cdef str PROJECT_NAME = "PROJECT_NAME"
cdef str TABLE_NAME = "TABLE_NAME"


cdef tuple project_check_and_creation(void* directory, void* config_file, void* output_directory, str biometadb_project,
                               void* luigi_programs_classes_list, object CallingClass):
    """
    
    :param directory: 
    :param config_file: 
    :param output_directory: 
    :param biometadb_project: 
    :param luigi_programs_classes_list: 
    :param CallingClass: 
    :return: 
    """
    # Ensure that all values are valid
    assert os.path.exists((<object>directory)) and os.path.exists((<object>config_file)), \
        AssertString.INVALID_PARAMETERS_PASSED
    # Load config file as object
    cdef object cfg = ConfigManager((<object>config_file))
    # Declaration for iteration
    cdef object val
    # Create directories as needed
    if not os.path.exists((<object>output_directory)):
        # Output directory
        os.makedirs((<object>output_directory))
        for val in (<object>luigi_programs_classes_list):
            os.makedirs(os.path.join((<object>output_directory), str(getattr(val, OUTPUT_DIRECTORY))))
    # Declarations
    cdef str genome_list_path = os.path.join((<object>output_directory), getattr(CallingClass, LIST_FILE))
    cdef str alias
    cdef str table_name
    # Write list of all files in directory as a list file
    write_genome_list_to_file((<void *>directory), (<void *>genome_list_path))
    # Load biometadb info
    if biometadb_project == "None":
        try:
            biometadb_project = cfg.get(BioMetaDBConstants.BIOMETADB, BioMetaDBConstants.DB_NAME)
        except NoOptionError:
            biometadb_project = getattr(CallingClass, PROJECT_NAME)
    # Get table name from config file or default
    try:
        table_name = cfg.get(BioMetaDBConstants.BIOMETADB, BioMetaDBConstants.TABLE_NAME)
    except NoOptionError:
        table_name = getattr(CallingClass, TABLE_NAME)
    # Get alias from config file or default
    try:
        alias = cfg.get(BioMetaDBConstants.BIOMETADB, BioMetaDBConstants.ALIAS)
    except NoOptionError:
        alias = "None"
    return genome_list_path, alias, table_name, biometadb_project, cfg


cdef void write_genome_list_to_file(void* directory, void* outfile):
    """  Function writes

    :param directory:
    :param outfile:
    :return:
    """
    cdef str _file
    cdef object W = open((<object>outfile), "w")
    for _file in os.listdir((<object>directory)):
        W.write("%s\n" % os.path.join((<object>directory), (<object>_file)))
    W.close()
