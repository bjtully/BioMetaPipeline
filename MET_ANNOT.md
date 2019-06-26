# MET_ANNOT

## About

**MET_ANNOT** uses `prodigal`, `kofamscan`, `interproscan`, `PROKKA`, `VirSorter`, `psortb`, `signalp`, and `KEGGDecoder`
to structurally and functionally annotate contig data. This will generate a final `BioMetaDB` project containing integrated 
results of this pipeline. An additional `.tsv` output file is generated for each "pipe" in the pipeline's config file.
The peptidase pipe requires the latest `dbCAN` and `CAZy` HMM profiles, whose links are available on the main README.
The peptidase pipe also requires the file `merops-as-pfams.txt`, which is available in `Sample/Data`. 

- Required flags
    - --directory (-d): /path/to/directory of fasta files
    - --config_file (-c): /path/to/config.ini file matching template in Sample/Config
- Optional flags
    - --output_directory (-o): Output prefix
    - --biometadb_project (-b): Name to assign to `BioMetaDB` project, or name of existing project to use
    - --cancel_autocommit (-a): Cancel creation/update of `BioMetaDB` project
    - --type_file (-t): /path/to/type_file, formatted as `'file_name.fna\t[Archaea/Bacteria]\t[gram+/gram-]\n'`
        - This argument is only required if running the **peptidase** portion of the pipeline.

## Example

- `pipedm MET_ANNOT -d fasta_folder/ -c metagenome_annotation.ini -o annot 2>annot.err`
- This command will use the fasta files in `fasta_folder/` in the annotation pipeline. It will output to the folder
`annot` and will use the config file entitled `metagenome_annotation.ini` to name the output database and to determine 
individual program arguments. Debugging and error messages will be saved to `annot.err`.
- This pipeline will generate a series of tables - a summary table, whose name is user-provided in the config file, as 
well as an individual table for each genome provided that describes annotations for each protein sequence identified
from the starting contigs.
<pre><code>SUMMARIZE:	View summary of all tables in database
 Project root directory:	Planctomycetes
 Name of database:		Planctomycetes.db

*******************************************************************************
	        Table Name:	phycisphaera-sp-norp138
	 Number of Records:	1607      

	        Column Name	Average             	Std Dev     

	num_phage_contigs_1	#.###               	#.###       
	num_phage_contigs_2	#.###               	#.###       
	num_phage_contigs_3	#.###               	#.###       
	    num_prophages_1	#.###               	#.###       
	    num_prophages_2	#.###               	#.###       
	    num_prophages_3	#.###               	#.###       
-------------------------------------------------------------------------------

	        Column Name	Most Frequent       	Count Non-Null

	               cazy	(...)                	##        
	                cdd	(...)                	##        
	              hamap	(...)                	##        
	                 ko	(...)                	##        
	            panther	(...)                	##        
	               pfam	(...)                	##        
	             prodom	(...)                	##        
	             prokka	(...)                	##        
	               sfld	(...)                	##        
	              smart	(...)                	##        
	        superfamily	(...)                	##        
	            tigrfam	(...)                	##        
-------------------------------------------------------------------------------</code></pre>
- View the summary table using `dbdm SUMMARIZE -c Metagenomes/ -t annotation`
<pre><code>SUMMARIZE:	View summary of all tables in database
 Project root directory:	Metagenomes
 Name of database:		Metagenomes.db
 
******************************************************************************************************************
                                                 Table Name:	annotation  
                                          Number of Records:	##         

                                                 Column Name	Average     	Std Dev   

                                  3hydroxypropionate_bicycle	#.###       	#.###       
                          4hydroxybutyrate3hydroxypropionate	#.###       	#.###       
                                                    adhesion	#.###       	#.###       
                                             alcohol_oxidase	#.###       	#.###       
                                                alphaamylase	#.###       	#.###       
                             alt_thiosulfate_oxidation_doxad	#.###       	#.###       
                              alt_thiosulfate_oxidation_tsda	#.###       	#.###       
                                            aminopeptidase_n	#.###       	#.###       
                                   ammonia_oxidation_amopmmo	#.###       	#.###              
                (...)            
                                          competence_factors	#.###       	#.###       
                           competencerelated_core_components	#.###       	#.###       
                        competencerelated_related_components	#.###       	#.###       
                                      cp_lyase_cleavage_phnj	#.###       	#.###       
                                             cplyase_complex	#.###       	#.###       
                                              cplyase_operon	#.###       	#.###       
                                 curli_fimbriae_biosynthesis	#.###       	#.###             
                (...)           
                                                     rubisco	#.###       	#.###       
                                                      secsrp	#.###       	#.###       
                     serine_pathwayformaldehyde_assimilation	#.###       	#.###       
                               soluble_methane_monooxygenase	#.###       	#.###       
                                             sulfhydrogenase	#.###       	#.###       
                                           sulfide_oxidation	#.###       	#.###       
                                       sulfite_dehydrogenase	#.###       	#.###       
                               sulfite_dehydrogenase_quinone	#.###       	#.###       
                                     sulfolipid_biosynthesis	#.###       	#.###       
                (...)          
                                          type_iii_secretion	#.###       	#.###       
                                           type_iv_secretion	#.###       	#.###       
                                         type_vabc_secretion	#.###       	#.###       
                                           type_vi_secretion	#.###       	#.###       
                             ubiquinolcytochrome_c_reductase	#.###       	#.###       
                                    vanadiumonly_nitrogenase	#.###       	#.###       
                                                vtype_atpase	#.###       	#.###       
                                               woodljungdahl	#.###       	#.###       
                                       xaapro_aminopeptidase	#.###       	#.###       
                                       zinc_carboxypeptidase	#.###       	#.###       
------------------------------------------------------------------------------------------------------------------</code></pre>

## MET_ANNOT type file

Peptidase predictions are incorporated into the **MET_ANNOT** pipeline, which requires users to provide additional information
about domain and membrane types. This info should be provided in a separate file and passed to `pipedm` from the command line 
using the `-t` flag. The format of this file should include the following info, separated by tabs, with one line per fasta file 
passed to pipeline:

<pre><code>[fasta-file]\t[bacteria/archaea]\t[gram+/gram-]\n</code></pre> 

This file is only required if running the **peptidase** portion of the pipeline.
    
## MET_ANNOT config file

The **MET_ANNOT** default config file allows for paths to calling programs to be set, as well as for program-level flags 
to be provided. Note that individual flags (e.g. those that are passed without arguments) are set using `FLAGS`. 
Ensure that all paths are valid (the bash command `which <COMMAND>` is useful for locating program paths).

Users may select which portions of the **MET_ANNOT** pipeline that they wish to run. **MET_ANNOT** determines valid pipes
from the user-provided config file and builds its pipeline accordingly.

### Configuring a pipeline

The **MET_ANNOT** config file is divided by "pipes" representing available annotation steps. 

- Location: `Examples/Config/MET_ANNOT.ini`
<pre><code># MET_ANNOT.ini
# Default config file for running the MET_ANNOT pipeline
# Users are recommended to edit copies of this file only

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The following **MUST** be set

[PRODIGAL]
PATH = /usr/bin/prodigal
-p = meta
FLAGS = -m

[HMMSEARCH]
PATH = /usr/bin/hmmsearch
-T = 75

[HMMCONVERT]
PATH = /usr/bin/hmmconvert

[HMMPRESS]
PATH = /usr/bin/hmmpress

[BIOMETADB]
PATH = /path/to/BioMetaDB/dbdm.py
--db_name = Metagenomes
FLAGS = -s

[DIAMOND]
PATH = /path/to/diamond


# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The following pipe sections may optionally be set
# Ensure that the entire pipe section is valid,
# or deleted/commented out, prior to running pipeline


# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Peptidase annotation

[CAZY]
DATA = /path/to/dbCAN-fam-HMMs.txt

[MEROPS]
DATA = /path/to/MEROPS.pfam.hmm
DATA_DICT = /path/to/merops-as-pfams.txt

[SIGNALP]
PATH = /path/to/signalp

[PSORTB]
PATH = /path/to/psortb

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# KEGG pathway annotation

[KOFAMSCAN]
PATH = /path/to/kofamscan/exec_annotation
--cpu = 1

[BIODATA]
PATH = /path/to/KEGGDecoder

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PROKKA

[PROKKA]
PATH = /path/to/prokka
FLAGS = --addgenes,--addmrna,--usegenus,--metagenome,--rnammer
--evalue = 1e-10
--cpus = 2

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# InterproScan

[INTERPROSCAN]
PATH = /path/to/interproscan.sh
--applications = TIGRFAM,SFLD,SMART,SUPERFAMILY,Pfam,ProDom,Hamap,CDD,PANTHER
FLAGS = --goterms,--iprlookup,--pathways

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# VirSorter

[VIRSORTER]
PATH = /path/to/virsorter-data
--db = 2
--user = UID-of-user-from-etc/passwd-file</code></pre>

- General Notes
    - Depending on the number of genomes, the completion time for this pipeline can vary from several hours to several days.
    - `BioData` requires a valid `pip` installation as well as a downloaded copy of the github repository.
    - As this script will create multiple tables in a **BioMetaDB** project, neither the flag `--table_name` nor `--alias`
     should be provided in the relevant section of the config script. 
    - `psortb` PERL scripts for command-line versions of the program call `sudo`. Either remove this from the script using
    `sed -i 's/sudo //g' /path/to/psortb`, or ensure that docker access is available.
    - The `virsorter` pipe offers the ability to pass user info to its calling program, `docker`, thus removing the need to 
    run using root.

### A note on flags

In general, program flags/arguments that filter or reduce output are supported, and thus can be provided in the user-passed
config file. However, flags that change the output of individual programs may cause unsuspected issues, and thus are not
recommended.
