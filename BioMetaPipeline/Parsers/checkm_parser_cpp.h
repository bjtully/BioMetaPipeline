#ifndef CHECKM_PARSER_CPP_H
#define CHECKM_PARSER_CPP_H

#include <string>
#include <vector>

typedef std::vector<std::vector<std::string> > string_vec_list;

namespace checkm {
    class CheckMParser_cpp {
        public:
            CheckMParser_cpp(std::string fileName);
            ~CheckMParser_cpp();
            void readFile();
            string_vec_list getValues();
        private:
            std::string fileName;
            string_vec_list records;
    };
}

#endif
