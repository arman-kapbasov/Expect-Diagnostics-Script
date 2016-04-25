============================================
Switch Expect Diagnostic Data Script
============================================

Script to help retrieve information from switches including: processes running, system version, coredumps, etc.


diagnosticsDataExpect.sh Usage
============================================

To run:
        ./diagnosticsDataExpect.sh [IP/Hostname] [port_num *optional*]

	add -h for HELP menu

Default output:
        [hostname]_[date]_opsDiag.tar.gz

You can change port by adding 2nd command line argument (optional):
        ./diagnosticsDataExpect.sh [IP/Hostname] [port]

Extract tar/output file with: tar -zxvf [filename]

