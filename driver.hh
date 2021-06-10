
#ifndef DRIVER_HH_
# define DRIVER_HH_

#include <string>
#include <iostream>
#include <cstddef> 
#include <fstream>
#include <unordered_map>
#include <sstream>

namespace kabsa {
    class Parser;
    class Scanner;
    class location;

    class Driver {
        public:
	        // std::unordered_map<std::string, Node> symbol_table;

            Driver(std::string input_file, std::string output_directory, std::string filename);
            ~Driver();

            void reset();
            int parse();
            int parse_file(const std::string& path);
            bool write_outfile(const std::stringstream& ss);
            void set_output_directory(const std::string directory);


        private:
            Scanner*      scanner_;
            Parser*       parser_;
            location*     location_;
            std::string   output_directory;
            std::string   input_file;
            std::string   filename;


            friend class  Parser;
            friend class  Scanner;
    };
}

#endif

