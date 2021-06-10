#include "driver.hh"
#include "parser.tab.hh"
#include "scanner.hh"


namespace kabsa {
    Driver::Driver(std::string input_file, std::string output_directory, std::string filename) : scanner_ (new Scanner()), parser_ (new Parser(*this)), location_ (new location()) {
        this->input_file = input_file;
        this->output_directory = output_directory;
        this->filename = filename;
    }

    Driver::~Driver() { delete parser_; delete scanner_; delete location_; }

    void Driver::reset() {
        delete location_;
        location_ = new location();
    }

    int Driver::parse() {
        scanner_->switch_streams(&std::cin, &std::cerr);
        parser_->parse();
        return 0;
    }

    int Driver::parse_file (const std::string& path) {
        std::ifstream s(path.c_str(), std::ifstream::in);
        scanner_->switch_streams(&s, &std::cerr);
        parser_->parse();
        s.close();
        return 0;
    }

    bool Driver::write_outfile(const std::stringstream& ss) {
        std::ofstream outfile(output_directory + "/" + filename + ".asm");
        if(!outfile.is_open()) {
            std::cout<< "Unable to create file at the given directory" << std::endl;
            return false;
        }
        outfile<< ss.rdbuf();
        outfile.close();
        std::cout<< "Assembly file created at: \""<< output_directory << "\", with name: \"" << filename << ".asm\"" << std::endl;
        return true;
    }
}
