#include <sstream>
#include <string>
#include <fstream>
#include "checkm_parser.h"

/*
Class CheckMParser parses the output of CheckM
CheckMParser will read file and return a vector of vector of strings

*/

namespace checkm {
    CheckMParser_cpp::CheckMParser_cpp(std::string fileName) {
        this->fileName = fileName;
    }

    CheckMParser_cpp::~CheckMParser_cpp() {}

    void CheckMParser_cpp::readFile() {
        std::ifstream file(this->fileName);
        std::string line;
        std::string token;
        size_t pos = 0;
        getline(file, line);
        while (!line.empty()) {
            //Skip over first 3 lines
            getline(file, line);
            getline(file, line);
            std::vector<std::string> line_data;
            while ((pos = line.find(" ") != std::string::npos)) {
                token = line.substr(0, pos);
                line_data.push_back(token);
                line.erase(0, pos + 1);
            }
            this->records.push_back(line_data);
            getline(file, line);
        }
        file.close();
    }

    string_vec_list CheckMParser_cpp::getValues() {
        return this->records;
    }

}
