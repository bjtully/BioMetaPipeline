#include "reader_cpp.h"
#include <iostream>
#include <algorithm>

/*
    Handles parsing kofam results file and functional profile data files
    Determines presence of complete metabolic function
    Class will be called through Cython

*/

namespace reader {
    ProfileReader::ProfileReader() {}

    ProfileReader::ProfileReader(std::ifstream& profile, std::ifstream& kofamRes) {
        profileFile = &profile;
        this->loadkofamResultsFile(kofamRes);
    }

    void ProfileReader::printKOResults() {
        for (std::set<std::string>::iterator it = this->kofamResults.begin(); it != this->kofamResults.end(); ++it) {
            std::cout << *it << std::endl;
        }
    }

    void ProfileReader::loadkofamResultsFile(std::ifstream& kofamResFile) {
        /*  Method saves all K##### values into object member std::set<std::string>

        */
        std::ifstream* fp = &kofamResFile;
        const std::string THRESHOLD_MET = "*";
        const size_t THRESHOLD_MET_SIZE = THRESHOLD_MET.size();
        std::string line;
        std::string token;
        // Skip first two header lines
        getline(*fp, line);
        getline(*fp, line);
        while(!(*fp).eof()) {
            getline(*fp, line);
            if (line.compare(0, THRESHOLD_MET_SIZE, THRESHOLD_MET) == 0) {
                // Erase parts of line that come before KO number
                token = ProfileReader::getToken(line);
                // Add to set of located KO values, as integers
                this->kofamResults.insert(
                    token.substr(0, token.length())
                );
            }
        }
    }

    std::string ProfileReader::getToken(std::string line) {
        /*  Method parses a string for KO value (token)

        */
        unsigned int locInLine = 0;
        const unsigned int KO_LOCATION_IN_FILE = 3;
        const std::string DELIMITER = " ";
        size_t pos = line.find(DELIMITER);
        std::string token = line.substr(0, pos);
        // KO number is 3rd col around unknown amount of whitespace
        while (locInLine < KO_LOCATION_IN_FILE) {
            if (token.length() > 0) {
                locInLine += 1;
                if (locInLine == 3) break;
            }
            line.erase(0, pos + DELIMITER.length());
            pos = line.find(DELIMITER);
            token = line.substr(0, pos);
        }
        return token;
    }

    std::string ProfileReader::searchNext(std::vector<std::pair<std::string, std::string> >& resVec) {
        /*  Public method iterators over member file pointer for metabolic functions
            resVec is filled with results

        */
        std::string line;
        std::vector<std::pair<std::string, std::string> >* resultsVector = &resVec;
        std::vector<std::pair<int, std::string> > parenthesisVector;
        const std::string COMMENT_CHAR = "#";
        const size_t COMMENT_CHAR_SIZE = COMMENT_CHAR.size();
        // Clear old entries
        if (resultsVector->size() > 0) resultsVector->clear();
        // Read over comment lines
        getline(*this->profileFile, line);
        while (line.compare(0, COMMENT_CHAR_SIZE, COMMENT_CHAR) == 0) {
            getline(*this->profileFile, line);
        }
        // Near-standardize line
        this->adjustLineToNearStandard(line);
        // Parse parenthesis line into levels
        this->determineParentheticContents(line, parenthesisVector);
        // Reverse sort
        std::sort(parenthesisVector.begin(), parenthesisVector.end(), std::greater<std::pair<int, std::string> >());
        // for (int i=0; i<parenthesisVector.size(); ++i) 
        // { 
        //     // "first" and "second" are used to access 
        //     // 1st and 2nd element of pair respectively 
        //     std::cout << parenthesisVector[i].first << " "
        //         << parenthesisVector[i].second << std::endl; 
        // }
        // Return string with replaced syntax for loading into python
        return this->evaluate(parenthesisVector);
    }

    void ProfileReader::adjustLineToNearStandard(std::string line) {
        /*  Method will remove "convenience" characters and replace with
            *extra* whitespace character

        */
        size_t pos;
        std::string toReplace[] = {"\r\n", "\n", "\t", "  ", "    "};
        // Replace convenience characters with single whitespace char      
        for (size_t i = 0; i < sizeof(toReplace) / sizeof(toReplace[0]); ++i) {
            pos = line.find(toReplace[i]);
            while (pos != std::string::npos) {
                line.replace(pos, toReplace[i].length(), " ");
                pos = line.find(toReplace[i]);
            }
        }
    }

    void ProfileReader::determineParentheticContents(std::string line, std::vector<std::pair<int, std::string> >& parVec) {
        /*  Method parses nested parenthetical expressions

        */
        std::vector<int> stack;
        std::vector<std::pair<int, std::string> >* parenthesisVector = &parVec;
        int start;
        for (size_t i = 0; i < line.length(); ++i) {
            if (line.compare(i, 1, "(") == 0) {
                stack.push_back(i);
            } else if (line.compare(i, 1, ")") == 0) {
                start = stack.back();
                stack.pop_back();
                parenthesisVector->push_back(std::make_pair(stack.size(), line.substr(start + 1, i - start - 1)));
            }
        }
    }

    std::string ProfileReader::evaluate(std::vector<std::pair<int, std::string> >& parVec) {
        /*  Method will evaluate parenthetical levels, replace in n - 1 levels, and
            return a final float value indicating if the metabolic function is present

        */
        std::vector<std::pair<int, std::string> >* parenthesisVector = &parVec;
        std::vector<std::pair<std::string, std::string> > stringToEvaluation;
        const std::string DELIMITER = " ";
        const unsigned int HIGHEST_LEVEL = parenthesisVector->at(0).first;
        size_t pos;
        std::string token;
        std::string line;
        std::string returnLine;
        for (unsigned int i = HIGHEST_LEVEL; i >= 0; i--) {
            // Evaluate by level
            if (parenthesisVector->at(0).first == i) {
                line = parenthesisVector->at(i).second;
                // Replace from lower level
                if (stringToEvaluation.size() > 0) {
                    line = ProfileReader::replaceInString(line, stringToEvaluation.back().first, stringToEvaluation.back().second);
                }
                // Store original string as key in map with default value
                // Note that python boolean representations are used for final step
                stringToEvaluation.push_back(std::make_pair(line, "False"));
                // Split line by delimiter
                while ((pos = line.find(DELIMITER)) != std::string::npos) {
                    token = line.substr(0, pos);
                    if (token.length() != 0) {
                        // Line is an or function
                        if (token.compare("or") == 0) {
                            
                        }
                        // Line is a float function
                    }
                    line.erase(0, pos + DELIMITER.length());
                }
           }
       }
       return returnLine;
    }

    std::string ProfileReader::replaceInString(std::string line, std::string replaceText, std::string replaceWith) {
        /*  Method handles simple search and replacement within a string

        */
        size_t pos;
        while ((pos = line.find(replaceText)) != std::string::npos) {
            line.replace(pos, replaceText.size(), replaceWith);
        }
        return line;
    }

    std::string ProfileReader::searchAndReplace(std::string kValue) {
        std::set<std::string>::iterator it;
        if ((it = this->kofamResults.find(kValue)) != this->kofamResults.end()) {

        }
    }

}