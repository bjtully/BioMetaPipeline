#include <string>
#include <fstream>
#include <iostream>
#include "fasta_parser_cpp.h"

/*
Class will parse fasta and return vector string arrays, indices are fasta id,
remaining header values, and fasta record

*/

namespace fasta_parser {
    FastaParser_cpp::FastaParser_cpp() {}

    FastaParser_cpp::FastaParser_cpp(std::ifstream& f, std::string delim = " ",
                std::string head = ">") {
        fastaFile = &f;
        delimiter = delim;
        header = head;
        last_line = "";
    }

    FastaParser_cpp::~FastaParser_cpp() {}

    std::vector<std::string> FastaParser_cpp::get() {
        std::string line;
        std::string dataLine;
        std::vector<std::string > line_data;
        size_t pos = 0;
        if (!(*this->fastaFile).eof()) {
            if (this->last_line != "") {
                line = this->last_line;
            }
            while (line.compare(0, this->header.length(), this->header) != 0) {
                getline((*this->fastaFile), line);
            }
            pos = line.find(this->delimiter);
            line_data.push_back(line.substr(1,pos));
            line_data.push_back(line.substr(pos + 1, line.length()));
            getline((*this->fastaFile), line);
            while (line.compare(0, this->header.length(), this->header) != 0 && !(*this->fastaFile).eof()) {
                dataLine.append(line);
                getline((*this->fastaFile), line);
            }
            line_data.push_back(dataLine);
            this->last_line = line;
        }
        return line_data;
    }

    void FastaParser_cpp::grab(std::vector<std::string>& ld) {
        std::string line;
        std::string dataLine;
        std::vector<std::string>* line_data = &ld;
        if (line_data->size() > 0) {
            line_data->clear();
        }
        size_t pos = 0;
        if (!(*this->fastaFile).eof()) {
            if (this->last_line != "") {
                line = this->last_line;
            }
            while (line.compare(0, this->header.length(), this->header) != 0) {
                getline((*this->fastaFile), line);
            }
            pos = line.find(this->delimiter);
            line_data->push_back(line.substr(1,pos));
            line_data->push_back(line.substr(pos + 1, line.length()));
            getline((*this->fastaFile), line);
            while (line.compare(0, this->header.length(), this->header) != 0 && !(*this->fastaFile).eof()) {
                dataLine.append(line);
                getline((*this->fastaFile), line);
            }
            line_data->push_back(dataLine);
            this->last_line = line;
        }
    }

}
