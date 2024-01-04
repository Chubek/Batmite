%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef struct {
    char* instruction;
    int cost;
    char* action;
} InstructionInfo;


typedef struct {
    char* tile;
    int cost;
    char* action;
} TileInfo;


typedef struct {
    char* rule;
    int cost;
    char* action;
} GrammarRule;

typedef struct {
    int cost;
    char* tile;
} OptimalCost;


void addInstruction(char* instruction, int cost, char* action);
int computeOptimalCost(DAGNode* node, int tileIndex, InstructionInfo* instructions, TileInfo* tiles, OptimalCost** optimalCostTable, int numTiles);
void addTile(char* tile, int cost, char* action);
void addGrammarRule(char* rule, int cost, char* action);
void findOptimalTiling();
void emitCodeForNode(DAGNode* node, int tileIndex, InstructionInfo* instructions, TileInfo* tiles, OptimalCost** optimalCostTable, int numInstructions); 
void emitCode();

%}

%union {
    int intval;
    char* strval;
}

%token <strval> INSTRUCTION TILE
%token <intval> COST
%token <strval> ACTION
%token NEWLINE

%%

program: /* empty */
       | program rule NEWLINE { addGrammarRule($2, $3, $4); }
       | program instruction NEWLINE { addInstruction($2, $3, $4); }
       | program tile NEWLINE { addTile($2, $3, $4); }

rule: INSTRUCTION ':' COST ACTION { $$ = strdup($1); }

instruction: INSTRUCTION ':' COST ACTION { $$ = strdup($1); }

tile: TILE ':' COST ACTION { $$ = strdup($1); }

%%

int main() {
    yyparse();  
    findOptimalTiling();
    emitCode();
    return 0;
}

void yyerror(const char* s) {
    fprintf(stderr, "Parser error: %s\n", s);
    exit(EXIT_FAILURE);
}

void addInstruction(char* instruction, int cost, char* action) {
    
    InstructionInfo* info = (InstructionInfo*)zalloc(sizeof(InstructionInfo));
    info->instruction = strdup(instruction);
    info->cost = cost;
    info->action = strdup(action);
    
}

void addTile(char* tile, int cost, char* action) {
    
    TileInfo* tileInfo = (TileInfo*)zalloc(sizeof(TileInfo));
    tileInfo->tile = strdup(tile);
    tileInfo->cost = cost;
}

void findOptimalTiling() {    
    int numInstructions = 0; 
    int numTiles = 0; 
    
    OptimalCost** optimalCostTable = (OptimalCost**)zalloc(numInstructions * sizeof(OptimalCost*));
    for (int i = 0; i < numInstructions; ++i) {
        optimalCostTable[i] = (OptimalCost*)zalloc(numTiles * sizeof(OptimalCost));
        for (int j = 0; j < numTiles; ++j) {
            optimalCostTable[i][j].cost = INT_MAX;  
            optimalCostTable[i][j].tile = NULL;
        }
    }

    
    computeOptimalCost(dag, 0, instructions, tiles, optimalCostTable, numTiles);  
    
}


int computeOptimalCost(DAGNode* node, int tileIndex, InstructionInfo* instructions, TileInfo* tiles, OptimalCost** optimalCostTable, int numTiles) {
    if (node->type == INSTRUCTION_NODE) {        
        int currentCost = instructions[node->instructionIndex].cost + tiles[tileIndex].cost;        
        if (currentCost < optimalCostTable[node->instructionIndex][tileIndex].cost) {
            optimalCostTable[node->instructionIndex][tileIndex].cost = currentCost;
            optimalCostTable[node->instructionIndex][tileIndex].tile = tiles[tileIndex].tile;
        }
        return currentCost;
    }
    
    int optimalCost = INT_MAX;

    for (int i = 0; i < numTiles; ++i) {
        int costWithTile = computeOptimalCost(node->left, i, instructions, tiles, optimalCostTable, numTiles) + computeOptimalCost(node->right, tileIndex, instructions, tiles, optimalCostTable, numTiles);

        if (costWithTile < optimalCost) {
            optimalCost = costWithTile;
        }
    }

    return optimalCost;
}


void emitCode(void) {    
    int numInstructions = 0;   
    emitCodeForNode(dag, 0, instructions, tiles, optimalCostTable, numInstructions);  
}


void emitCodeForNode(DAGNode* node, int tileIndex, InstructionInfo* instructions, TileInfo* tiles, OptimalCost** optimalCostTable, int numInstructions) {    
    if (node->type == INSTRUCTION_NODE) {        
        printf("%s %s\n", instructions[node->instructionIndex].action, optimalCostTable[node->instructionIndex][tileIndex].tile);
        return;
    }  
    
    int minTileIndex = 0;
    int minCost = optimalCostTable[node->instructionIndex][0].cost;

    for (int i = 1; i < numInstructions; ++i) {
        if (optimalCostTable[node->instructionIndex][i].cost < minCost) {
            minCost = optimalCostTable[node->instructionIndex][i].cost;
            minTileIndex = i;
        }
    }    
    emitCodeForNode(node->left, minTileIndex, instructions, tiles, optimalCostTable, numInstructions);
    emitCodeForNode(node->right, tileIndex, instructions, tiles, optimalCostTable, numInstructions);
}


