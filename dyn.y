%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>

static inline int min(int a, int b) {
    return (a < b) ? a : b;
}

typedef enum {
	REGISTER_GENERAL,
	REGISTER_EXTENDED,
	REGISTER_FLOATING,
	REGISTER_SIMD,
	REGISTER_SEGMENT,
	REGISTER_INSTPOINTER,
	REGISTER_STATUS,
	REGISTER_MODELSPECIFIC,
	REGISTER_PROGRRAMCOUNTER,
	REGISTER_STACKPOINTER,
	REGISTER_FRAMEPOINTER,
	REGISTER_LINK,
	REGISTER_SYSTEM,
	REGISTER_TLB,
	REGISTER_EXCEPTION,
	REGISTER_INTEGER,
	REGISTER_VECTOR,
	REGISTER_ZERO,
	REGISTER_GLOBAL,
	REGISTER_LOCAL,
} RegisterKind;

typedef enum {
    DATA_MOVEMENT,
    ARITHMETIC,
    LOGICAL,
    COMPARISON,
    CONTROL_TRANSFER,
    BIT_MANIPULATION,
    STRING,
    FLOATING_POINT,
    SYSTEM,   
    SIMD
    MEMORY_ACCESS,
    EXCEPTION_SYNCHRONIZATION,
    ARITHMETIC_LOGICAL,
    ATOMIC,
    MEMORY_ORDERING,
} MachineOpcodeKind;

typedef enum {
   CONSTANT,
   REGISTER,
} TreeLeafKind;

typedef struct {
       RegisterKind kind;
       int number;
       char *name;
} Register;

typedef struct {
	char *name;
	MachineOpcodeKind kind;
} MachineOpcode;

typedef struct TreeNode {
    IROpcode opcode;
    TreeLeafKind kind;
    struct TreeNode* left;
    struct TreeNode* right;
} TreeNode;

typedef struct SubtreeInfo {
    TreeNode *root;
    Register *registers;
    int numRegisters;
} SubtreeInfo;



%}

%union {
    char *strVal;
    int intVal;
    Tree *treeVal;
    ActionFunction actionFnVal;
    RegisterKind regkindVal;
    MachineOpcodeKind machineOpcodeVal;
}

%token <strVal> LEAF_VALUE ACTION_CONTEXT ACTION_TREE REGISTER_NAME REGISTER_PCNT OPCODE_PCNT OPCODE_NAME SIGMA
%token <regkindVal> REGISTER_KIND
%token <machineOpcodeVal> OPCODE_KIND
%type <treeVal> tree leaf

%%

opcode_decl: OPCODE_PCNT OPCODE_NAME
	   | OPCODE_PCNT OPCODE_NAME OPCODE_KIND

register_decl: REGISTER_PCNT REGISTER_NAME 
	     | REGISTER_PCNT REGISTER_NAME REGISTER_KIND

action: /* empty */
      '{' SIGMA '}'

tree: /* empty */ 	{ $$ = createTree(); }
    | leaf         	{ $$ = $1; }

leaf: LEAF            	{ $$ = createLeaf($1); }
    | leaf '<' tree '>' { $$ = addLeft($1, $3->root, $2); }
    | leaf '>' tree '<' { $$ = addRight($1, $3->root, $2); }


%%

int main(void) {
    yyparse();
    return 0;
}

uint32_t hashTreeNode(const TreeNode* node) {
    if (node == NULL) {
        return 0;
    }

    uint32_t hash = hashIROpcode(node->opcode) ^ hashKind(node->kind);
    hash ^= hashTreeNode(node->left);
    hash ^= hashTreeNode(node->right);

    return hash == 0 ? 1 : hash;
}

TreeNode* createNode(IROpcode data, TreeLeafKind kind) {
    TreeNode* newNode = (TreeNode*)malloc(sizeof(TreeNode));
    if (newNode == NULL) {
        perror("Memory allocation failed");
        exit(EXIT_FAILURE);
    }

    newNode->data = data;
    newNode->kind = kind;
    newNode->left = NULL;
    newNode->right = NULL;

    return newNode;
}

TreeNode* insert(TreeNode* root, IROpcode data, TreeLeafKind kind) {
    if (root == NULL) {
        return createNode(data, kind);
    }

    if (data < root->data) {
        root->left = insert(root->left, data);
    } else if (data > root->data) {
        root->right = insert(root->right, data);
    }

    return root;
}

void issueInstruction(TreeNode *node) {    
    if (node->left == NULL && node->right == NULL) {        
        printf("LOAD R%d, %d\n", node->registers->number, node->operand);
    } else {
        
        printf("OP R%d, R%d, R%d\n",
               node->registers->number,
               node->left->registers->number,
               node->right->registers->number);
    }
}



SubtreeInfo *computeOptimalSubtreeHelper(TreeNode *root, int *costMatrix, int *optimalSplit) {
    SubtreeInfo *subtree = zalloc(sizeof(SubtreeInfo));
    subtree->root = root;

    if (root->left == NULL && root->right == NULL) {
        
        subtree->numRegisters = 0; 
        return subtree;
    }

    
    SubtreeInfo *leftSubtree = computeOptimalSubtreeHelper(root->left, costMatrix, optimalSplit);
    SubtreeInfo *rightSubtree = computeOptimalSubtreeHelper(root->right, costMatrix, optimalSplit);

    
    int currentCost = leftSubtree->numRegisters + rightSubtree->numRegisters + 1;

    
    int minCost = currentCost;
    int splitPoint = -1;

    for (int i = 1; i <= leftSubtree->numRegisters; i++) {
        int splitCost = costMatrix[leftSubtree->numRegisters] +
                        costMatrix[rightSubtree->numRegisters + i] + currentCost;

        if (splitCost < minCost) {
            minCost = splitCost;
            splitPoint = i;
        }
    }

    
    costMatrix[leftSubtree->numRegisters + rightSubtree->numRegisters] = minCost;
    optimalSplit[leftSubtree->numRegisters + rightSubtree->numRegisters] = splitPoint;
    
    subtree->numRegisters = minCost;
    return subtree;
}


void initializeArrays(int numRegisters, int *costMatrix, int *optimalSplit) {
    for (int i = 0; i <= numRegisters; i++) {
        costMatrix[i] = -1;  
        optimalSplit[i] = -1; 
    }

    
    costMatrix[0] = 0;
}


SubtreeInfo computeOptimalSubtree(TreeNode *root) {
    SubtreeInfo subtree;
    subtree->root = root;

    if (root == NULL) {
        subtree->numRegisters = 0;
        return subtree;
    }

    
    int numRegisters = 0;
    while (1) {
        int *costMatrix = (int *)malloc((numRegisters + 1) * sizeof(int));
        int *optimalSplit = (int *)malloc((numRegisters + 1) * sizeof(int));

        initializeArrays(numRegisters, costMatrix, optimalSplit);       
        SubtreeInfo *result = computeOptimalSubtreeHelper(root, costMatrix, optimalSplit);        
        if (result->numRegisters <= numRegisters) {
            
            subtree = result;
            break;
        }

        
        numRegisters++;
        free(costMatrix);
        free(optimalSplit);
    }

    return subtree;
}


Register *createRegister(int number, RegisterKind kind, char *registerName) {
    Register reg = zalloc(sizeof(Register));
    reg->number = number;
    reg->kind = kind;
    reg->name = name;
    
    return reg;
}


void updateRegisterAllocationHelper(TreeNode *root, Register *registers, int *optimalSplit) {
    if (root->left == NULL && root->right == NULL) {        
        return;
    }

    int splitPoint = optimalSplit[root->left->numRegisters + root->right->numRegisters];

    root->left->registers = registers;
    root->right->registers = registers + root->left->numRegisters + splitPoint;

    
    updateRegisterAllocationHelper(root->left, registers, optimalSplit);
    updateRegisterAllocationHelper(root->right, registers + root->left->numRegisters + splitPoint, optimalSplit);
}


void updateRegisterAllocation(SubtreeInfo *subtree) {
   subtree->registers = (Register *)malloc(subtree->numRegisters * sizeof(Register));

    for (int i = 0; i < subtree->numRegisters; i++) {
        subtree->registers[i] = createRegister(i + 1);
    }
    
    updateRegisterAllocationHelper(subtree->root, subtree->registers, optimalSplit);
}


Register alloc(Register *registers, int numRegisters, int *usedRegisters) {
    for (int i = 0; i < numRegisters; i++) {
        if (!usedRegisters[i]) {
            usedRegisters[i] = 1; 
            return registers[i];
        }
    }

    fprintf(stderr, "Error: No available registers\n");
    exit(EXIT_FAILURE);
}


Register* generateCode(TreeNode *node, int j) {
    if (node == NULL) {
        return NULL;
    }

    int k = 0; 
    Register *registers[k];

    
    for (int t = 1; t <= k; t++) {
        registers[t - 1] = generateCode(subtree, j - t + 1);
    }

    
    Register *result;
    if (k > 0) {
        result = registers[0];
    } else {
        result = alloc();
    }

    issueInstruction(node->operator, result, registers, k);
    return result;
}


void yyerror(const char* s) {
    fprintf(stderr, "Parser error: %s\n", s);
    exit(EXIT_FAILURE);
}

