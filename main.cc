#include "driver.hh"
#include <string>

int main() {
    kabsa::Driver driver;
    driver.parse_file(std::string("D:/Projects/kabsa/examples/test_1.kabsa"));
    return 0;
}
