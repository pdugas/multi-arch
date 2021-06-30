#include <stdio.h>
#include <stdlib.h>

#ifndef VERSION
#define VERSION "unknown"
#endif

int main(int argc, char **argv, char **env)
{
    printf("eg %s\n", VERSION);
    printf("Howdy!\n");

    return EXIT_SUCCESS;
}
