#include <stdio.h>

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
