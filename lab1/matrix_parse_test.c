#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main()
{
    int rows, cols;

    printf("Enter number of rows: ");
    scanf("%d", &rows);
    printf("Enter number of columns: ");
    scanf("%d", &cols);

    int matrix[rows][cols];

    srand(time(NULL));

    for (int i = 0; i < rows; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            matrix[i][j] = rand() % 100 + 1;
        }
    }

    printf("\n");
    for (int i = 0; i < rows; i++)
    {
        for (int j = 0; j < cols; j++)
        {
            printf("%3d ", matrix[i][j]);
        }
        printf("\n");
    }

    printf("\n");
    int max = 0;

    for (int j = 0; j <= cols / 2; j++)
    {
        for (int i = j; i < rows - j; i++)
        {
            printf("%3d ", matrix[i][j]);
            if (matrix[i][j] > max)
            {
                max = matrix[i][j];
            }
        }
        printf("\n");
    }

    for (int j = cols - 1; j >= cols / 2; j--)
    {
        for (int i = cols - j - 1; i < rows - cols + j + 1; i++)
        {
            printf("%3d ", matrix[i][j]);
            if (matrix[i][j] > max)
            {
                max = matrix[i][j];
            }
        }
        printf("\n");
    }

    printf("\nMaximum in shaded area: %d\n", max);

    return 0;
}
