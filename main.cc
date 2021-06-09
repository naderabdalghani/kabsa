#include "driver.hh"
#include <string>

std::string get_filename(const std::string& path) {
    std::size_t found = path.find_last_of("/\\");
    std::size_t dot = path.find(".");
    int filename_length = dot - found - 1;
    return path.substr(found+1, filename_length);
}

int main(int argc, char *argv[]) {
    // Argv -> input_file, output_directory
    if(argc != 3) {
        std::cout<<"ERROR: you must enter a valid input and output directories\n";
        return 0;
    }
    std::string input_path = argv[1];
    std::string output_path = argv[2];
    std::cout<<argc<<std::endl;
    std::string filename = get_filename(input_path);
    kabsa::Driver driver(input_path, output_path, filename);
    driver.parse_file(input_path);
    return 0;
}
