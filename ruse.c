#include <stdio.h>
#include <stdlib.h>

typedef struct {
  int version;
  int index;
} SSAOperand;

typedef enum {
  IR_ADD,
  IR_SUB,
  IR_MUL,
  IR_DIV,
  IR_ASSIGN,
  IR_LOAD,
  IR_STORE,
  IR_PHI,
} IROpcode;

typedef struct {
  int isConstant;
  int value;
} IROperand;

typedef struct {
  IROpcode opcode;
  SSAOperand result;
  IROperand operand1;
  IROperand operand2;
} IRInstruction;

typedef struct {
  IROpcode opcode;
  SSAOperand result;
  SSAOperand operand1;
  SSAOperand operand2;
} PhiInstruction;

typedef struct {
  enum {
    INST_PHI,
    INST_INS,
  } kind;

  union {
    PhiInstruction phiInstruction;
    IRInstruction irInstruction;
  };
} Instruction;

typedef struct {
  Instruction *instructions;
  int numInstructions;
} BasicBlock;

typedef struct {
  BasicBlock *basicBlocks;
  int numBlocks;
} IRFunction;

typedef struct {
  IRFunction *functions;
  int numFunctions;
} IRProgram;

IRInstruction createIRInstruction(IROpcode opcode, SSAOperand result,
                                  IROperand operand1, IROperand operand2) {
  IRInstruction instruction;
  instruction.opcode = opcode;
  instruction.result = result;
  instruction.operand1 = operand1;
  instruction.operand2 = operand2;
  return instruction;
}

PhiInstruction createPhiInstruction(SSAOperand result, SSAOperand operand1,
                                    SSAOperand operand2) {
  PhiInstruction phiInstruction;
  phiInstruction.opcode = IR_PHI;
  phiInstruction.result = result;
  phiInstruction.operand1 = operand1;
  phiInstruction.operand2 = operand2;
  return phiInstruction;
}


#include <stdio.h>
#include <stdlib.h>


struct BasicBlock;


typedef struct {
  struct BasicBlock* source;
  struct BasicBlock* destination;
} CFGEdge;


typedef struct BasicBlock {
  
  Instruction* instructions;
  int numInstructions;

  
  CFGEdge* successors;  
  int numSuccessors;

  CFGEdge* predecessors;  
  int numPredecessors;

  int blockID;  
} BasicBlock;


typedef struct {
  BasicBlock* basicBlocks;
  int numBlocks;
} ControlFlowGraph;


BasicBlock createBasicBlock(void) {
  BasicBlock block;
  
  block.instructions = NULL;
  block.numInstructions = 0;
  block.successors = NULL;
  block.numSuccessors = 0;
  block.predecessors = NULL;
  block.numPredecessors = 0;
  block.blockID = -1;  
  return block;
}


ControlFlowGraph createControlFlowGraph(void) {
  ControlFlowGraph cfg;
  
  cfg.basicBlocks = NULL;
  cfg.numBlocks = 0;
  return cfg;
}


void addEdge(BasicBlock* source, BasicBlock* destination) {
  
  source->successors = realloc(source->successors, (source->numSuccessors + 1) * sizeof(CFGEdge));
  source->successors[source->numSuccessors].source = source;
  source->successors[source->numSuccessors].destination = destination;
  source->numSuccessors++;

  
  destination->predecessors = realloc(destination->predecessors, (destination->numPredecessors + 1) * sizeof(CFGEdge));
  destination->predecessors[destination->numPredecessors].source = source;
  destination->predecessors[destination->numPredecessors].destination = destination;
  destination->numPredecessors++;
}


ControlFlowGraph initializeCFG(void) {
  ControlFlowGraph cfg;
  cfg.basicBlocks = malloc(2 * sizeof(BasicBlock));  

  
  cfg.basicBlocks[0] = createBasicBlock();
  cfg.basicBlocks[1] = createBasicBlock();

  
  cfg.basicBlocks[0].blockID = 0;
  cfg.basicBlocks[1].blockID = 1;

  
  addEdge(&cfg.basicBlocks[0], &cfg.basicBlocks[1]);

  cfg.numBlocks = 2;
  return cfg;
}


