#! /bin/bash
# Copyright (C) 2017 Vincent Zvikaramba
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CMD_HELPER=$(mktemp)
CMD_HELPER_SRC="${CMD_HELPER}.c"

function extract_code {
# save the source code to a temp file
logb "\t\tExtracting code..."
cat <<SRC > ${CMD_HELPER_SRC}
#define _XOPEN_SOURCE 600
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <errno.h>
#include <getopt.h>

#define SCRIPT_TEMPLATE "RB_"
// global variables for keeping parsed cmd line arguments.
int silent=0;
int sync_all=0;
int sync_vendor=0;
int job=0;
int build=0;
int with_su=0;
int odin=0;
int clean_flag=0;
char target[256];
char type[256];
char distro[256];
char device_name[256];
char output_dir[256];
char android_top[256];
int eflag = 0;

/* Helper function that parses command line arguments to main
 */
void parse_commmand_line(int argc, char *argv[]) {

    //variable to store return status of getopt().
    int opt;
    int optind = 0;
    int tflag = 0;
    int nflag = 0;
    int pflag = 0;
    int oflag = 0;
    int dflag = 0;

	static struct option long_options[] = {
		/* *name ,  has_arg,           *flag,  val */
		{"silent",	no_argument,       0, 's' },
		{"sync",	no_argument,       0, 'v' },
		{"sync_all",	no_argument,       0, 'a' },
		{"su",	no_argument,       0, 'u' },
		{"odin",	no_argument,       0, 'c' },
		{"help",	no_argument, 0,  'h' },
		{"clean",	no_argument, 0,  'r' },
		{"target",	required_argument, 0,  't' },
		{"device",	required_argument, 0,  'n' },
		{"path",	required_argument, 0, 'p'  },
		{"output",	required_argument, 0, 'o'  },
		{"distro",	required_argument, 0,  'd' },
		{"type",	required_argument, 0,  'e' },
		{"fast-charge", no_argument, 0,  'f' },
		{"wifi-fix",    no_argument, 0,  'w' },
		{"oc",          no_argument, 0,  'z' },
		{0,         0,                 0,  0 }
	};

    while ( (opt = getopt_long (argc, argv, "t:n:j:p:o:b:d:e:scravuhfwz", long_options, &optind)) != -1 ) {
        switch (opt){
            case 'f': //fast-charge
            case 'w': //wifi fix
            case 'z': //oc
            case 'a': //sync
            case 'v': //sync
		break;
            case 'u':
		with_su=1;
		break;
            case 'r': //clean
		clean_flag=1;
		break;
	    case 's': //silent
		silent=1;
                break;
            case 'e': //build type
		strcpy(type, optarg);
		eflag = 1;
                break;
	    case 'c': //odin
		odin=1;
                break;
            case 't': // target
		strcpy(target, optarg);
		tflag = 1;
                break;
            case 'n': // device
		strcpy(device_name, optarg);
		nflag = 1;
                break;
            case 'j': //job
            //get the number provided with the argument.
                job = atoi (optarg);
                break;
            case 'p': //path
		strcpy(android_top, optarg);
		pflag = 1;
                break;
            case 'o': // output
		strcpy(output_dir, optarg);
		oflag = 1;
                break;
            case 'b': //make this optional
            //get the number provided with the argument.
                build = atoi (optarg);
                break;
            case 'd': //distro
		strcpy(distro, optarg);
		dflag = 1;
                break;
            case 'h': // case in which the argument is not recognised.
            //No break statement == the case 'falls thru' to the next one.
                fprintf (stderr, "Usage: %s [OPTION]\n",argv[0]);
                fprintf (stderr, "  -d, --distro\tdistribution name\n" );
                fprintf (stderr, "  -t, --target\twhere target is one of bootimage|recoveryimage|otapackage\n" );
                fprintf (stderr, "  -e, --type\twhere type is one of user|userdebug|eng\n" );
                fprintf (stderr, "  -n, --device\tdevice name\n" );
                fprintf (stderr, "  -p, --path\tbuild top path\n" );
                fprintf (stderr, "  -o, --output\toutput path (path to jenkins archive dir)\n");
                fprintf (stderr, "\nOptional commands:\n");
                fprintf (stderr, "  -b\tbuild number\n");
                fprintf (stderr, "  -s, --silent\tdon't publish to Telegram\n");
                fprintf (stderr, "  -c, --odin\tbuild compressed (ODIN) images\n");
                fprintf (stderr, "  -r, --clean\tclean build directory on completion\n");
                fprintf (stderr, "  -a, --sync_all\tSync entire build tree\n");
                fprintf (stderr, "  -v, --sync\tSync device/kernel/vendor trees\n");
                fprintf (stderr, "  -u, --su\tAdd SU to build\n");
                fprintf (stderr, "  -j\tnumber of parallel make jobs to run\n");
                exit (EXIT_FAILURE);
            default: // if an invalid argument is found.
                fprintf (stderr, "Usage: %s [OPTION]\n",argv[0]);
                fprintf (stderr, "  -d, --distro\tdistribution name\n" );
                fprintf (stderr, "  -t, --target\twhere target is one of bootimage|recoveryimage|otapackage\n" );
                fprintf (stderr, "  -e, --type\twhere type is one of user|userdebug|eng\n" );
                fprintf (stderr, "  -n, --device\tdevice name\n" );
                fprintf (stderr, "  -p, --path\tbuild top path\n" );
                fprintf (stderr, "  -o, --output\toutput path (path to jenkins archive dir)\n");
                fprintf (stderr, "\nOptional commands:\n");
                fprintf (stderr, "  -b\tbuild number\n");
                fprintf (stderr, "  -s, --silent\tdon't publish to Telegram\n");
                fprintf (stderr, "  -c, --odin\tbuild compressed (ODIN) images\n");
                fprintf (stderr, "  -r, --clean\tclean build directory on completion\n");
                fprintf (stderr, "  -a, --sync_all\tSync entire build tree\n");
                fprintf (stderr, "  -v, --sync\tSync device/kernel/vendor trees\n");
                fprintf (stderr, "  -u, --su\tAdd SU to build\n");
                fprintf (stderr, "  -j\tnumber of parallel make jobs to run\n");
		exit (EXIT_FAILURE);
	}
    }

    if ( (argc < 6) && !(sync_all || sync_vendor)) {
                fprintf (stderr, "Usage: %s [OPTION]\n",argv[0]);
                fprintf (stderr, "  -d, --distro\tdistribution name\n" );
                fprintf (stderr, "  -t, --target\twhere target is one of bootimage|recoveryimage|otapackage\n" );
                fprintf (stderr, "  -e, --type\twhere type is one of user|userdebug|eng\n" );
                fprintf (stderr, "  -n, --device\tdevice name\n" );
                fprintf (stderr, "  -p, --path\tbuild top path\n" );
                fprintf (stderr, "  -o, --output\toutput path (path to jenkins archive dir)\n");
                fprintf (stderr, "\nOptional commands:\n");
                fprintf (stderr, "  -b\tbuild number\n");
                fprintf (stderr, "  -s, --silent\tdon't publish to Telegram\n");
                fprintf (stderr, "  -c, --odin\tbuild compressed (ODIN) images\n");
                fprintf (stderr, "  -r, --clean\tclean build directory on completion\n");
                fprintf (stderr, "  -a, --sync_all\tSync entire build tree\n");
                fprintf (stderr, "  -u, --su\tAdd SU to build\n");
                fprintf (stderr, "  -v, --sync\tSync device/kernel/vendor trees\n");
                fprintf (stderr, "  -j\tnumber of parallel make jobs to run\n");
        exit (EXIT_FAILURE);
    }

    if ( (sync_all == 0) && (sync_vendor == 0) ) {
	    if ( dflag == 0 ) {
		fprintf (stderr, "%s: Missing -d (distro) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
	    if ( tflag == 0 ) {
		fprintf (stderr, "%s: Missing -t (target) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
	    if ( nflag == 0 ) {
		fprintf (stderr, "%s: Missing -n (device name) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
	    if ( oflag == 0 ) {
		fprintf (stderr, "%s: Missing -o (output path) option. \n", argv[0]);
		exit (EXIT_FAILURE);
	    }
    }
    if ( pflag == 0 ) {
        fprintf (stderr, "%s: Missing -p (build path) option. \n", argv[0]);
        exit (EXIT_FAILURE);
    }
}

void write_src_file() {

	// get a temp name
	char * temp_name = tempnam( "/tmp", SCRIPT_TEMPLATE);

	FILE * temp_file;

	// if we can't get a random name, just use a fixed one.
	if ( temp_name == NULL ) {
		temp_name = "/tmp/RB_src";
	}

	// exit if we can't open the file
	if ( ( temp_file = fopen(temp_name, "w" ) ) == NULL ) {
		perror("fopen");
		exit(EXIT_FAILURE);
	}

	// start writing the env variables to the file
	fprintf ( temp_file, "#!/bin/bash\n");
	fprintf ( temp_file, "silent=%d\n", silent );
	fprintf ( temp_file, "build_num=%d\n", build );
	fprintf ( temp_file, "clean_target_out=%d\n", clean_flag );

	// set the su property
	if (with_su) fprintf ( temp_file, "WITH_SU=true\n");
		else fprintf ( temp_file, "WITH_SU=false\n");

	// set the job number
	if (job) fprintf ( temp_file, "job_num=%d\n", job );

	// set the build type
	if (eflag) fprintf ( temp_file, "build_type=%s\n", type );
		else  fprintf ( temp_file, "build_type=userdebug\n");

	fprintf ( temp_file, "with_odin=%d\n", odin );
	fprintf ( temp_file, "target=%s\n", target );
	fprintf ( temp_file, "distro=%s\n", distro );
	fprintf ( temp_file, "device_name=%s\n", device_name );
	fprintf ( temp_file, "out_dir=%s\n", output_dir );
	fprintf ( temp_file, "android_top=%s\n", android_top );

	// close the file
	fclose(temp_file);

	// print the temp name
	printf("%s\n", temp_name);

	// free the name
	free(temp_name);

}

/* Main function
 */
int main(int argc, char *argv[]){

	//parse the command line arguments.
	parse_commmand_line ( argc, argv );
	// write the source file
	write_src_file ();
    return 0;
}
SRC
}

PATCH_FUNCTIONS=("${PATCH_FUNCTIONS[@]}" "extract_code")
