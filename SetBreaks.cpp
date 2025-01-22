// * * * Auto insert break points and memory tag in DebuggerAutorun // * * * 
// Version 1
// Detects <bp>, <m1>, and <M2> tags in source code
// Sets breaks and memory tags accordingly in DebuggerAutorun.txt
// Preserves other text lines in DebuggerAutorun.txt

#include <iostream>
#include <fstream> 
#include <string>
#include <stdlib.h>
#include <algorithm> // needed for transform
using namespace std;

const int MAXBREAK = 1000;          // max number of breaks in code
const string tag = "<bp>";
const string autoruntag = "bp ";
const string tagm1 = "<m1>";
const string autoruntagm1 = "m1 ";
const string tagm2 = "<m2>";
const string autoruntagm2 = "m2 ";
const string tagsym = "<sym>";
const string autoruntagsym = "sym ";
const string tagsequ = "<sequ>";
const string autoruntagsequ = "sym ";

const string autodebug_file_name = "DebuggerAutorun.txt";

//-------------------------------------------------------
//  Change this value according to your program name  //|
const string project_name = "cw";                     //|
//-------------------------------------------------------

// trim string
inline std::string trim(std::string& str)
{
    str.erase(str.find_last_not_of(' ')+1);         //suffixing spaces
    str.erase(0, str.find_first_not_of(' '));       //prefixing spaces
    return str;
}

int main () {

    // var
    string breaks[MAXBREAK];
    string sym[MAXBREAK];
    string symlib[MAXBREAK];  
    string symequ[MAXBREAK];
    string symequlib[MAXBREAK];      

    std::ifstream source_file; 
    std::string source_line;
    int curbreak = 0;
    int cursym = 0;
    int cursymequ = 0;

    string nobreaks[MAXBREAK];
    std::ifstream autodebug_file;
    std::string debugger_line;
    int no_break_counter = 0;

    std::ofstream autodebug_file_out;

    // read DebuggerAutorun.txt
    // and store not breakpoint in an array, not m1/m2 lines in strings, 
    // and not symbols in an array
    autodebug_file.open(autodebug_file_name);
    while (getline (autodebug_file,debugger_line))
    {
        // trim current line
        trim(debugger_line); 
        // lowercase current line 
        std::transform(debugger_line.begin(), debugger_line.end(), debugger_line.begin(),::tolower);
        size_t nbfound = debugger_line.find(autoruntag); 
        size_t nbfound2 = debugger_line.find(autoruntagm1); 
        size_t nbfound3 = debugger_line.find(autoruntagm2); 
        size_t nbfound4 = debugger_line.find(autoruntagsym); 
        size_t nbfound5 = debugger_line.find(autoruntagsequ); 
        if (
        (nbfound == string::npos) 
        & (nbfound2 == string::npos) 
        & (nbfound3 == string::npos) 
        & (nbfound4 == string::npos)
        & (nbfound5 == string::npos)
        & (no_break_counter < MAXBREAK))
        {
            nobreaks[no_break_counter] = debugger_line;
            no_break_counter++;
        }
    }
    autodebug_file.close();

    // reset DebuggerAutorun.txt
    // and write not bp and not m1/m2 lines and not sym 
    // all this line were saved in an array previously (see above)
    autodebug_file_out.open(autodebug_file_name);
    for (int i=0;i<no_break_counter;i++)
    {
        autodebug_file_out << nobreaks[i] <<"\n";
    }

    // read source file
    // to find breaks tags, m1/m2, sym and sequ
    source_file.open(project_name + "_Output.txt");
    string m1str = "";
    string m2str = "";
    while (getline (source_file, source_line)) 
    {
        // find breaks
        if ((source_line.find(tag) != string::npos) & (curbreak < MAXBREAK)){
            // display line whith a break
            cout << source_line << "\n";
            // find  "/" in that line
            size_t charfound = source_line.find("/");
            // extract address from that line (4 chars after /)
            std::string adresse = source_line.substr (charfound+1,4);
            // populate array 
            breaks[curbreak] = adresse;
            curbreak++;
        }   
        // find m1 tag
        else {
            if (source_line.find(tagm1) != string::npos) {
            // display line whith m1 tag
            cout << source_line << "\n";
            // read next line
            getline (source_file, source_line); 
            // find  "/" in that line
            size_t charfound2 = source_line.find("/");
            // extract address from that line (4 chars after /)
            m1str = source_line.substr (charfound2+1,4);
            }

        // find m1 tag
            if (source_line.find(tagm2) != string::npos) {
            // display line whith m2 tag
            cout << source_line << "\n";
            // read next line
            getline (source_file, source_line); 
            // find  "/" in that line
            size_t charfound2 = source_line.find("/");
            // extract address from that line (4 chars after /)
            m2str = source_line.substr (charfound2+1,4); 
            }

        // find sym tag
            if (source_line.find(tagsym) != string::npos) {
            // display line whith sym tag
            cout << source_line << "\n";
            // find  "/" in that line
            size_t charfound2 = source_line.find("/");
            // extract address from that line (4 chars after /)
            // populate array 
            sym[cursym] = source_line.substr (charfound2+1,4);
            // *********
            // get next line
            getline (source_file, source_line);
            int pos = source_line.find_last_of("|")+2 ;
            int pos2 = source_line.find_first_of(" ", pos);
            symlib[cursym] = source_line.substr(pos,pos2-pos);
            cursym++;            
            }

        // find sequ tag
            if (source_line.find(tagsequ) != string::npos) {
            // display line whith sym tag
            cout << source_line << "\n";
            // get next line
            getline (source_file, source_line);
            int pos = source_line.find_last_of("|")+2 ;
            int pos2 = source_line.find_first_of(" ", pos);
            // get label 
            symequlib[cursymequ] = source_line.substr(pos,pos2-pos);

            pos = source_line.find("equ",pos2)+5 ; // jump over "equ"
            // get address
            pos = source_line.find_last_of(" ",pos) + 1 ;
            pos2 = source_line.find_first_of(" ", pos);
            //store address in array
            symequ[cursymequ] = source_line.substr(pos,pos2-pos);
            cursymequ++;            
            }
        }
    }
    source_file.close();

    // write breaks to output file 
    if (curbreak >0) // = if a least 1 break found
    {
        for (int i = 0; i < curbreak; i++) {
        cout << "break ";
        cout << i << " : ";        // display index 
        cout << breaks[i] << "\n" ; // display address 
        // write break instructions in DebuDebuggerAutorun.txt file
        autodebug_file_out << "bp ";
        autodebug_file_out << breaks[i];
        autodebug_file_out << endl;
        }
    }
    // write m1 and m2 in output file 
    if  (m1str != "") {
            m1str = autoruntagm1 + m1str + "\n";
            cout << m1str;
            autodebug_file_out << m1str;
    }
    if  (m2str != "") {
            m2str = autoruntagm2 + m2str + "\n";
            cout << m2str;
            autodebug_file_out << m2str;
    }
    // write symbol in output file 
    if (cursym >0) // = if a least 1 sym found   
        for (int i = 0; i < cursym; i++) {
        string tempo = "sym " + symlib[i] + " = " + sym[i] ;
        cout << tempo << endl;
        // write break instructions in DebuDebuggerAutorun.txt file
        autodebug_file_out << tempo << endl;
        }

    // write equ symbol  in output file 
    if (cursymequ >0) // = if a least 1 sym found   
        for (int i = 0; i < cursymequ; i++) {
        string tempo = "sym " + symequlib[i] + " = " + symequ[i] ;
        cout << tempo << endl;
        // write break instructions in DebuDebuggerAutorun.txt file
        autodebug_file_out << tempo << endl;
        }  

    autodebug_file_out.close();
    
} // end
