#ifndef READER_CPP_H
#define READER_CPP_H

#include <vector>
#include <string>
#include <map>
#include <set>
#include <fstream>

namespace reader {
    class ProfileReader {
        public:
            ProfileReader();
            ProfileReader(std::ifstream&, std::ifstream&);
            std::string searchNext(std::vector<std::pair<std::string, std::string> >&);
            void printKOResults();
        private:
            std::ifstream* profileFile;
            std::map<std::string, bool> searchedKOValues;
            std::set<std::string> kofamResults;
            void loadkofamResultsFile(std::ifstream&);
            void adjustLineToNearStandard(std::string);
            void determineParentheticContents(std::string, std::vector<std::pair<int, std::string> >&);
            std::string evaluate(std::vector<std::pair<int, std::string> >&);
            std::string getToken(std::string);
            std::string replaceInString(std::string, std::string, std::string);
            std::string searchAndReplace(std::string);
    };

}


#endif