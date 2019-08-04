# distutils: language = c++
from io import StringIO
from libcpp.string cimport string
from libcpp.vector cimport vector

""" Class populates list of citations based on pipeline.
Outputs a .txt file of sample in-text citations and references.

"""

OUTPUT_ORDER = (
    "$metsanity",
    "$checkm",
    "$fastani",
    "$gtdbtk",
    "$prodigal",
    "$prokka",
    "$rnammer",
    "$diamond",
    "$hmmer",
    "$kofamscan",
    "$biodata",
    "interproscan",
    "$psortb",
    "$signalp",
    "$virsorter"
)

CITATIONS = {
    "$metsanity": {
        "citation": " Neely C. 2020. METsanity: Pipeline for major biological analyses. https://github.com/cjneely10/BioMetaPipeline.",
        "dependencies": [],
        "version:": "latest",
        "in-text": "The genomic analysis was completed using METsanity $version (Neely 2020)."
    },
    "$checkm": {
        "citation": "Parks DH, Imelfort M, Skennerton CT, Hugenholtz P, Tyson GW. 2015. CheckM: assessing the quality of microbial genomes recovered from isolates, single cells, and metagenomes. Genome Research, 25: 1043–1055.",
        "dependencies": [
            "$pplacer",
            "$prodigal",
            "$HMMER"
        ],
        "version": "v1.0.13",
        "in-text": "CheckM $version$added_flags was used to estimate genome completion and contamination (Parks, Imelfort, Skennerton, Hugenholtz, & Tyson, 2015)."
    },
    "$pplacer": {
        "citation": "Matsen FA, Kodner RB, Armbrust EV. 2010. pplacer: linear time maximum-likelihood and Bayesian phylogenetic placement of sequences onto a fixed reference tree. BMC Bioinformatics 11: doi:10.1186/1471-2105-11-538.",
        "dependencies": [],
        "version": "v1.1",
        "in-text": ""
    },
    "$hmmer": {
        "citation": "Eddy SR. 2011. Accelerated profile HMM searches. PLOS Comp. Biol., 7:e1002195.",
        "dependencies": [],
        "version": "v3.2.1b",
        "in-text": "HMM $version$added_flags profiles were generated by HMMER (Eddy 2011)."
    },
    "$gtdbtk": {
        "citation": "Parks DH, et al. 2018. A standardized bacterial taxonomy based on genome phylogeny substantially revises the tree of life. Nat. Biotechnol., http://dx.doi.org/10.1038/nbt.4229",
        "dependencies": [
            "$pplacer",
            "$fastani",
            "$prodigal",
            "$fasttree"
        ],
        "version": "v0.2.2",
        "in-text": "Phylogeny was determined using GTDBtk $version$added_flags (Parks et al., 2018)."
    },
    "$fastani": {
        "citation": "Jain C, et al. 2019. High-throughput ANI Analysis of 90K Prokaryotic Genomes Reveals Clear Species Boundaries. Nat. Communications, doi: 10.1038/s41467-018-07641-9.",
        "dependencies": [],
        "version": "v1.1",
        "in-text": "Average nucleotide identity and genome redundancy were determined using FastANI $version$added_flags (Jain et al., 2019)."
    },
    "$prodigal": {
        "citation": "Hyatt D, et al. 2010. Prodigal: prokaryotic gene recognition and translation initiation site identification. BMC Bioinformatics, 11:119. doi: 10.1186/1471-2105-11-119.",
        "dependencies": [],
        "version": "v2.6.3",
        "in-text": "Prodigal $version$added_flags was used to predict open reading frames within contigs (Hyatt et al., 2010)."
    },
    "$fasttree": {
        "citation": "Price MN, Dehal PS, Arkin AP. FastTree 2 - Approximately Maximum-Likelihood Trees for Large Alignments. PLoS One, 5, e9490.",
        "dependencies": [],
        "version": "2.1.10",
        "in-text": ""
    },
    "$diamond": {
        "citation": "Buchfink B, Xie C, Huson DH. Fast and sensitive protein alignment using DIAMOND. Nature Methods 12, 59-60 (2015). doi:10.1038/nmeth.3176",
        "dependencies": [],
        "version": "v0.9.23.124",
        "in-text": "Protein alignments were calculated using Diamond $version$added_flags (Buchfink, Xie, & Huson, 2015)."
    },
    "$kofamscan": {
        "citation": "Aramaki T., Blanc-Mathieu R., Endo H., Ohkubo K., Kanehisa M., Goto S., Ogata H. KofamKOALA: KEGG ortholog assignment based on profile HMM and adaptive score threshold. bioRxiv doi: https://doi.org/10.1101/602110 (2019).",
        "dependencies": [],
        "version": "",
        "in-text": "KEGG ontology was predicted by kofamscan $added_flags (Aramaki et al., 2019)."
    },
    "$biodata": {
        "citation": "Graham ED, Heidelberg JF, Tully BJ. (2018) Potential for primary productivity in a globally-distributed bacterial phototroph. ISME J 350, 1–6",
        "dependencies": [
            "$hmmer"
        ],
        "version": "v.1.0.1",
        "in-text": "KEGGDecoder $version$added_flags calculated KEGG pathway completion estimations (Graham, Heidelberg, & Tully, 2018)."
    },
    "$interproscan": {
        "citation": "Jones, P., Binns, D., Chang, H. Y., Fraser, M., Li, W., McAnulla, C., … Hunter, S. (2014). InterProScan 5: genome-scale protein function classification. Bioinformatics (Oxford, England), 30(9), 1236–1240. doi:10.1093/bioinformatics/btu031",
        "dependencies": [],
        "version": "5.32-71.0",
        "in-text": "InterProScan $version$added_flags calculated protein families and domains (Jones et al., 2014)."
    },
    "$prokka": {
        "citation": "Seemann T. Prokka: rapid prokaryotic genome annotation. Bioinformatics 2014 Jul 15;30(14):2068-9. PMID:24642063",
        "dependencies": [
            "$blast+",
            "$prodigal",
            "$hmmer",
            "$rnammer",
        ],
        "version": "1.13.3",
        "in-text": "PROKKA $version$added_flags provided whole genome annotation (Seeman 2014)."
    },
    "$blast+": {
        "citation": "Camacho C et al. BLAST+: architecture and applications. BMC Bioinformatics. 2009 Dec 15;10:421.",
        "dependencies": [],
        "version": "2.7.1",
        "in-text": ""
    },
    "$rnammer": {
        "citation": "Lagesen K et al. RNAmmer: consistent and rapid annotation of ribosomal RNA genes. Nucleic Acids Res. 2007;35(9):3100-8.",
        "dependencies": [],
        "version": "1.2",
        "in-text": "RNAmmer $version$added_flags was integrated into the PROKKA annotation suite (Lageson et al., 2007).",
    },
    "$virsorter": {
        "citation": "Roux, S., Enault, F., Hurwitz, B. L., & Sullivan, M. B. (2015). VirSorter: mining viral signal from microbial genomic data. PeerJ, 3, e985. https://doi.org/10.7717/peerj.985",
        "dependencies": [],
        "version": "v1.0.5",
        "in-text": "Contigs with phage and prophage signatures were identified using VirSorter $version $added_flags (Roux, Enault, Hurwitz, & Sullivan, 2015)."
    },
    "$psortb": {
        "citation": "N.Y. Yu, J.R. Wagner, M.R. Laird, G. Melli, S. Rey, R. Lo, P. Dao, S.C. Sahinalp, M. Ester, L.J. Foster, and F.S.L. Brinkman (2010) PSORTb 3.0: improved protein subcellular localization prediction with refined localization subcategories and predictive capabilities for all prokaryotes. Bioinformatics 26(13):1608-1615.",
        "dependencies": [],
        "version": "v.3.0",
        "in-text": "PSORTb $version$added_flags computationally predicted extracellularity within the gene calls (Yu et al., 2010)."
    },
    "$signalp": {
        "citation": "Nielsen H. (2017) Predicting Secretory Proteins with SignalP. In: Kihara D. (eds) Protein Function Prediction. Methods in Molecular Biology, vol 1611. Humana Press, New York, NY",
        "dependencies": [],
        "version": "4.1",
        "in-text": "SignalP $version$added_flags was integrated into the peptidase annotation pipeline to identify signal peptides (Nielson 2017).",
    }
}

cdef class CitationGenerator:
    cdef dict needed_citations
    cdef dict added_flags

    def __init__(self):
        """ Reads through list of pipes that were run and gathers needed citations

        """
        cdef str name
        self.needed_citations = {}
        self.added_flags = {}
        for name in ("$prodigal", "$hmmer", "$diamond", "$metsanity"):
            self.needed_citations[name] = CITATIONS[name]

    def add(self, str program, list added_flags):
        """ Adds program name to set of citations

        :param program:
        :param added_flags:
        :return:
        """
        # Ensure that program name is lower-cased
        cdef str name
        program = ("$%s" % program.replace("$", "")).lower()
        if program in CITATIONS.keys():
            # Add citation for program
            self.needed_citations[program] = CITATIONS[program]
            # Store added flags
            self.added_flags[program] = added_flags
            # Add dependencies if needed
            for name in CITATIONS[program]["dependencies"]:
                self.add(name, added_flags)

    def write(self, str txt_out):
        """

        :param txt_out:
        :return:
        """
        # Text output
        cdef object txt_W = open(txt_out, "w")
        txt_W.write("Sample in-text citations:\n\n")
        cdef str name, key
        cdef dict out_dict
        cdef list alphabetized_citations = sorted([self.needed_citations[key]["citation"] for key in self.needed_citations.keys()])
        for name in OUTPUT_ORDER:
            # Write sample in-text citations
            out_dict = self.needed_citations.get(name, None)
            if out_dict:
                txt_W.write(out_dict["in-text"]
                            .replace("$version", out_dict.get("version"))
                            .replace("$added_flags",
                                     (" (%s)" % ",".join(self.added_flags.get(name, "")).rstrip(","))
                                        if self.added_flags.get(name, "") != [] else "") + "\n\n")
        txt_W.write("\nReferences:\n\n")
        for name in alphabetized_citations:
            # Write references
            txt_W.write(name + "\n")
        txt_W.close()
