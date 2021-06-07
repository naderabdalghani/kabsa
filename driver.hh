
#ifndef DRIVER_HH_
# define DRIVER_HH_

# include <string>
# include <iostream>
# include <fstream>


namespace kabsa {
    class Parser;
    class Scanner;
    class location;

    class Driver {
        public:
            Driver();
            ~Driver();

            void reset();
            int parse();
            int parse_file(std::string& path);

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

