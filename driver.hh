
#ifndef DRIVER_HH_
# define DRIVER_HH_

#include <string>
#include <iostream>
#include <fstream>
#include <unordered_map>

namespace kabsa {
    class Parser;
    class Scanner;
    class location;

    class Driver {
        public:
	        // std::unordered_map<std::string, Node> symbol_table;

            Driver();
            ~Driver();

            void reset();
            int parse();
            int parse_file(const std::string& path);

        private:
            Scanner*      scanner_;
            Parser*       parser_;
            location*     location_;
            int           error_;

            friend class  Parser;
            friend class  Scanner;
    };
}

#endif

