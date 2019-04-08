#include <string>
#include <vector>
#include "tsv_parser_cpp.h"

/*
Class CheckMParser parses the output of CheckM
CheckMParser will read file and return a vector of vector of strings

*/

namespace tsv {
    TSVParser_cpp::TSVParser_cpp() {
    }

    TSVParser_cpp::TSVParser_cpp(std::string fileName) {
        this->fileName = fileName;
        this->headerLine = "";
    }

    void TSVParser_cpp::readFile(int skipLines = 0, std::string commentLineDelim = "#", bool headerLine = true) {

    }

}
