#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

char* encode(const char *string)
{
  int length = strlen(string);
  char *encoded = malloc(length);

  for (int i = 0; i < length; i++)
  {
    encoded[i] = string[i] + 3;
  }

  return encoded;
}

int main(void)
{
  clock_t start = clock();

  for (int i = 0; i < 1e6; i++)
  {
    encode("Hello, World!");
  }

  printf(
    "Program finished in %.6f seconds\n",
    (float) (clock() - start) / CLOCKS_PER_SEC
  );
}
