#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LEN 1024

int main(int argc, char *argv[]) {
    FILE *out, *myout, *diff;
    char line1[MAX_LEN], line2[MAX_LEN];
    int line_number = 0;

    if (argc != 4) {
        printf("Usage: %s <file1> <file2> <output_file>\n", argv[0]);
        return 1;
    }

    out = fopen(argv[1], "r");
    if (out == NULL) {
        printf("Error: could not open file %s\n", argv[1]);
        return 1;
    }

    myout = fopen(argv[2], "r");
    if (myout == NULL) {
        printf("Error: could not open file %s\n", argv[2]);
        fclose(out);
        return 1;
    }

    diff = fopen(argv[3], "w");
    if (diff == NULL) {
        printf("Error: could not open file %s\n", argv[3]);
        fclose(out);
        fclose(myout);
        return 1;
    }

    int has_diff = 0;
    while (fgets(line1, MAX_LEN, out) != NULL && fgets(line2, MAX_LEN, myout) != NULL) {
        line_number++;

        if (strcmp(line1, line2) != 0) {
            has_diff = 1;
            fprintf(diff, "Line %d:\n", line_number);
            fprintf(diff, "\tin file1: %s", line1);
            fprintf(diff, "\tin file2: %s", line2);
        }
    }

    if (has_diff == 0) {
        fprintf(diff, "No differences found.\n");
    } else {
        printf("Difference found for test case: %s\n", argv[1]);
    }

    fclose(out);
    fclose(myout);
    fclose(diff);

    return 0;
}