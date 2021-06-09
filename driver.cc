#include "driver.hh"
#include "parser.tab.hh"
#include "scanner.hh"


namespace kabsa {
    Driver::Driver() : scanner_ (new Scanner()), parser_ (new Parser(*this)), location_ (new location()) {}

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

    bool Driver::write_outfile(const std::string& path, const std::stringstream& ss) {
        std::ofstream outfile(path);
        if(!outfile.is_open())
            return false;
        outfile<< ss.rdbuf();
        outfile.close();
        return true;
    }
}
