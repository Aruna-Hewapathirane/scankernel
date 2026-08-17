# scan linux kernel function length
![Project Screenshot](Screenshot-from-2026-08-16-15-24-06.png)

# scankernel (Linux Kernel Function Length Scanner)
The Linux Kernel Function Length Scanner is a static analysis desktop application designed to audit and map the scale of C function implementations across the Linux kernel source tree. By scanning specified kernel directories, it extracts function signatures, maps their exact location, and calculates their line lengths

# Usage
Launch the application binary.  
Click the Browse button to select the target directory path containing your target Linux kernel source code (e.g., /home/user/linux/kernel).  
Click the Scan button to parse the source tree.  
Review the generated list containing:  
Length: Total number of lines occupied by the function implementation.  
Full File Path: Relative path down to the exact source file.  
Line #: Starting line of the specific function signature.  
Function Name / Signature: Fully parsed signature declaration.  
