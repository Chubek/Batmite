#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

typedef struct {
    char* label; 
    
} TreeGrammarNode;

typedef struct {
    char* mnemonic; 
    
} MachineInstruction;

typedef struct {
	
	int** table;
	int numRows; 
	int numCols; 
} DpTable;



DpTable initializeDPTable(int rows, int cols) {
    DpTable dpTable;
    numRows = rows;
    numCols = cols;

    dpTable.table = (int**)zalloc(numRows * sizeof(int*));
    for (int i = 0; i < numRows; ++i) {
        dpTable.table[i] = (int*)zalloc(numCols * sizeof(int));
        memset(dpTabl.table[i], -1, numCols * sizeof(int)); 
    }
}


int dpInstructionSelection(DpTable *dpTable, TreeGrammarNode* tree, int i, int j) {
    
    if (i == j) {
        return 0; 
    }

    if (dpTable->table[i][j] != -1) {
        return dpTable->table[i][j];
    }
    
    int minCost = INT_MAX;

    for (int k = i; k < j; ++k) {
        int cost = dpInstructionSelection(tree, i, k) +
                   dpInstructionSelection(tree, k + 1, j) +
                   costOfTile(tree, i, k, j); 
        if (cost < minCost) {
            minCost = cost;
        }
    }

    
    dpTable->table[i][j] = minCost;
    return minCost;
}


int costOfTile(TreeGrammarNode* tree, int i, int k, int j) {
    if (strcmp(tree[i].label, "ADD") == 0 && strcmp(tree[k + 1].label, "MUL") == 0) {
        return 2; 
    } else {
        return 1; 
    }
}


void performInstructionSelection(TreeGrammarNode* tree) {
    int totalCost = dpInstructionSelection(tree, 0, numRows - 1);
    printf("Total Cost of Instruction Selection: %d\n", totalCost);
}



