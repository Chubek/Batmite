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

typedef enum  {
    INST_PHI,
    INST_IR,
} InstructionKind;


typedef struct {
  InstructionKind kind;

  union {
    PhiInstruction phiInstruction;
    IRInstruction irInstruction;
  };
} Instruction;

typedef struct {
  Instruction *instructions;
  CFGBlock *cfgBlock;
  int numInstructions;
} InstructionBlock;

typedef struct {
  InstructionBlock *instructionBlocks;
  CFGBlock *entryCFGBlock;
  int numBlocks;
} IRFunction;

typedef struct {
  IRFunction *functions;
  int numFunctions;
} IRProgram;

Instruction *createIRInstruction(IROpcode opcode, SSAOperand result,
                                  IROperand operand1, IROperand operand2) {
  Instruction *instruction = zalloc(sizeof(Instruction));
  instruction->kind = INST_IR;
  instruction->irInstruction.opcode = opcode;
  instruction->irInstruction.result = result;
  instruction->irInstruction.operand1 = operand1;
  instruction->irInstruction.operand2 = operand2;
  return instruction;
}

Instruction *createPhiInstruction(SSAOperand result, SSAOperand operand1,
                                    SSAOperand operand2) {
  Instruction *instruction = zalloc(sizeof(Instruction));
  instruction->kind = INST_PHI;
  instruction->phiInstruction.opcode = IR_PHI;
  instruction->phiInstruction.result = result;
  instruction->phiInstruction.operand1 = operand1;
  instruction->phiInstruction.operand2 = operand2;
  return phiInstruction;
}



