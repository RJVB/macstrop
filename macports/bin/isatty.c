#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <errno.h>

#if !defined(linux) && !defined(__MACH__) && !defined(__ERRNO_H__)
extern char *sys_errlist[];
#endif

int main(int argc, char *argv[])
{
	errno= 0;
	if (argc == 2) {
		int ret = !isatty(atoi(argv[1]));
		if (errno) {
			perror(argv[1]);
		} else {
			exit(ret);
		}
	} else {
		fprintf(stderr, "isatty takes exactly 1 argument\n");
	}
	exit(-1);
}
