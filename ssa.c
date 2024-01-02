#include <math.h>
#include <stdio.h>
#include <stdlib.h>

typedef enum {
  UQUAD,
  QUAD,
  UDOUBLE,
  DOBULE,
  UHALF,
  HALF,
  UBYTE,
  BYTE,
  SINGLE_RATIONAL,
  DOUBLE_RATIONAL,
  BOOLEAN,
  POINTER,
} IRValueKind;

typedef struct Node {
  IRValueKind kind;
  union {
    unsigned long unsignedQuad;
    long signedQuad;
    unsigned int unsignedDouble;
    int signedDouble;
    unsigned short unsignedHalf;
    short signedHalf;
    unsigned char unsignedByte;
    char signedByte;
    float singleRational;
    double doubleRational;
    bool boolean;
    void *pointer;
  };
} IRValue;

typedef enum {
  IR_ADD,
  IR_SUB,
  IR_MUL,
  IR_DIV,
  IR_UDIV,
  IR_UREM,
  IR_POW,
  IR_MOD,
  IR_NEG,
  IR_AND,
  IR_OR,
  IR_XOR,
  IR_NOT,
  IR_LSR,
  IR_LSL,
  IR_ASR,
  IR_ULT,
  IR_ULE,
  IR_UGT,
  IR_UGE,
  IR_UEQ,
  IR_UNE,
  IR_LT,
  IR_LE,
  IR_GT,
  IR_GE,
  IR_EQ,
  IR_NE,
  IR_GOTO,
  IR_RETURN,
  IR_JUMP,
  IR_JUMP_IF_TRUE,
  IR_JUMP_IF_FALSE,
  IR_BLIT,
  IR_CALL,
  IR_HALT,
  IR_NOP,
  IR_LOAD_QUAD,
  IR_STORE_QUAD,
  IR_LOAD_DOUBLE,
  IR_STORE_DOUBLE,
  IR_LOAD_HALF,
  IR_STORE_HALF,
  IR_LOAD_BYTE,
  IR_STORE_BYTEi,
  IR_NULL,
  IR_ALLOCA_4B,
  IR_ALLOCA_8B,
  IR_ALLOCA_16B,
  IR_TRUNC_QUAD2DOUBLE_S,
  IR_TRUNC_QUAD2HALF_S,
  IR_TRUNC_QUAD2BYTE_S,
  IR_TRUNC_DOUBLE2HALF_S,
  IR_TRUNC_DOUBLE2BYTE_S,
  IR_TRUNC_HALF2BYTE_S,
  IR_TRUNC_QUAD2DOUBLE_U,
  IR_TRUNC_QUAD2HALF_U,
  IR_TRUNC_QUAD2BYTE_U,
  IR_TRUNC_DOUBLE2HALF_U,
  IR_TRUNC_DOUBLE2BYTE_U,
  IR_TRUNC_HALF2BYTE_U,
  IR_EXTEND_DOUBLE2QUAD_S,
  IR_EXTEND_HALF2QUAD_S,
  IR_EXTEND_BYTE2QUAD_S,
  IR_EXTEND_HALF2DOUBLE_S,
  IR_EXTEND_BYTE2DOUBLE_S,
  IR_EXTEND_BYTE2HALF_S,
  IR_EXTEND_DOUBLE2QUAD_U,
  IR_EXTEND_HALF2QUAD_U,
  IR_EXTEND_BYTE2QUAD_U,
  IR_EXTEND_HALF2DOUBLE_U,
  IR_EXTEND_BYTE2DOUBLE_U,
  IR_EXTEND_BYTE2HALF_U,
  IR_COPY_DATA,
  IR_PHI,
} IROpcode;

typedef struct {
  bool isConstant;
  IRValue value;
} IROperand;

typedef struct {
  int version;
  int index;
  IROperand *irValue;
} SSAOperand;

typedef struct {
  IROpcode opcode;
  bool isDead;
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

typedef enum {
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
  bool isAllDead;
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

typedef struct Node {
  IRValue *value;
  struct Node *next;
} Node;

typedef struct {
  Node *localVariables;
  Node *parameters;
  long returnAddress;
  long stackPointer;
} ActivationRecord;

IRValue createIRValue(IRValueKind kind, void *value) {
  IRValue irValue;
  irValue.kind = kind;

  switch (kind) {
  case UQUAD:
    irValue.unsignedQuad = *((unsigned long *)value);
  case QUAD:
    irValue.signedQuad = *((long *)value);
    break;
  case UDOUBLE:
    irValue.unsignedDouble = *((unsigned int *)value);
  case DOBULE:
    irValue.unsignedDouble = *((int *)value);
    break;
  case UHALF:
    irValue.unsignedHalf = *((unsigned short *)value);
  case HALF:
    irValue.signedHalf = *((short *)value);
    break;
  case UBYTE:
    irValue.unsignedByte = *((unsigned char *)value);
  case BYTE:
    irValue.signedByte = *((char *)value);
    break;
  case BOOLEAN:
    irValue.boolean = *((bool)value);
    break;
  case SINGLE_RATIONAL:
    irValue.singleRational = *((float)value);
    break;
  case DOUBLE_RATIONAL:
    irValue.doubleRational = *((double)value);
    break;
  case POINTER:
    irValue.pointer = value;
    break;
  default:
    break;
  }

  return irValue;
}

SSAOperand createSSAOperand(int version, int index, IROperand *irValue) {
  SSAOperand operand;
  operand.version = version;
  operand.index = index;
  operand.irValue = irValue;
  return operand;
}

IROperand createIROperand(int isConstant, int value) {
  IROperand operand;
  operand.isConstant = isConstant;
  operand.value = value;
  return operand;
}

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
  PhiInstruction instruction;
  instruction.opcode = IR_PHI;
  instruction.result = result;
  instruction.operand1 = operand1;
  instruction.operand2 = operand2;
  return instruction;
}

Instruction createInstruction(InstructionKind kind, PhiInstruction phiInstr,
                              IRInstruction irInstr) {
  Instruction instruction;
  instruction.kind = kind;

  if (kind == INST_PHI) {
    instruction.phiInstruction = phiInstr;
  } else {
    instruction.irInstruction = irInstr;
  }

  return instruction;
}

InstructionBlock createInstructionBlock(Instruction *instructions,
                                        CFGBlock *cfgBlock,
                                        int numInstructions) {
  InstructionBlock block;
  block.instructions = instructions;
  block.cfgBlock = cfgBlock;
  block.numInstructions = numInstructions;
  return block;
}

IRFunction createIRFunction(InstructionBlock *instructionBlocks,
                            CFGBlock *entryCFGBlock, int numBlocks) {
  IRFunction irFunc;
  irFunc.instructionBlocks = instructionBlocks;
  irFunc.entryCFGBlock = entryCFGBlock;
  irFunc.numBlocks = numBlocks;
  return irFunc;
}

IRProgram createIRProgram(IRFunction *functions, int numFunctions) {
  IRProgram program;
  program.functions = functions;
  program.numFunctions = numFunctions;
  return program;
}

Node *insert(Node *head, int data) {
  Node *newNode = (Node *)zalloc(sizeof(Node));
  newNode->data = data;
  newNode->next = head;
  return newNode;
}

ActivationRecord createActivationRecord(int returnAddress) {
  ActivationRecord record;
  record.localVariable = NULL;
  record.parameters = NULL;
  record.returnAddress = returnAddress;
  reocrd.stackPointer = 0;
}

void optimizeConstantFolding(IRFunction *irFunction) {
  for (int i = 0; i < irFunction->numBlocks; i++) {
    InstructionBlock *block = &irFunction->instructionBlocks[i];

    for (int j = 0; j < block->numInstructions; j++) {
      Instruction *instr = &block->instructions[j];

      if (instr->kind == INST_IR && instr->irInstruction.opcode != IR_PHI) {
        int resultValue = 0;

        switch (instr->irInstruction.opcode) {
        case IR_ADD:
          resultValue = instr->irInstruction.operand1.value +
                        instr->irInstruction.operand2.value;
          break;

        case IR_SUB:
          resultValue = instr->irInstruction.operand1.value -
                        instr->irInstruction.operand2.value;
          break;

        case IR_MUL:
          resultValue = instr->irInstruction.operand1.value *
                        instr->irInstruction.operand2.value;
          break;

        case IR_DIV:
          if (instr->irInstruction.operand2.value != 0) {
            resultValue = instr->irInstruction.operand1.value /
                          instr->irInstruction.operand2.value;
          } else {
          }
          break;

        case IR_MOD:
          if (instr->irInstruction.operand2.value != 0) {
            resultValue = instr->irInstruction.operand1.value %
                          instr->irInstruction.operand2.value;
          } else {
          }
          break;

        case IR_EQ:
          resultValue = (instr->irInstruction.operand1.value ==
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_NE:
          resultValue = (instr->irInstruction.operand1.value !=
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_GT:
          resultValue = (instr->irInstruction.operand1.value >
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_GE:
          resultValue = (instr->irInstruction.operand1.value >=
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_LT:
          resultValue = (instr->irInstruction.operand1.value <
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_LE:
          resultValue = (instr->irInstruction.operand1.value <=
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_AND:
          resultValue = (instr->irInstruction.operand1.value &&
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_OR:
          resultValue = (instr->irInstruction.operand1.value ||
                         instr->irInstruction.operand2.value)
                            ? 1
                            : 0;
          break;

        case IR_BITWISE_AND:
          resultValue = instr->irInstruction.operand1.value &
                        instr->irInstruction.operand2.value;
          break;

        case IR_BITWISE_OR:
          resultValue = instr->irInstruction.operand1.value |
                        instr->irInstruction.operand2.value;
          break;

        case IR_BITWISE_XOR:
          resultValue = instr->irInstruction.operand1.value ^
                        instr->irInstruction.operand2.value;
          break;

        default:
          break;
        }

        instr->kind = INST_IR;
        instr->irInstruction.opcode = IR_ASSIGN;
        instr->irInstruction.result.isConstant = 1;
        instr->irInstruction.result.value = resultValue;
        instr->irInstruction.operand1.value = 0;
        instr->irInstruction.operand2.value = 0;
      }
    }
  }
}

void optimizeStrengthReduction(IRInstruction *instructions,
                               int numInstructions) {
  for (int i = 0; i < numInstructions; i++) {
    IRInstruction *currentInstr = &instructions[i];

    if (currentInstr->opcode == IR_MUL) {
      if (currentInstr->operand1.isConstant &&
          currentInstr->operand2.isConstant) {
        currentInstr->opcode = IR_ADD;
        currentInstr->result.irValue->value =
            currentInstr->operand1.value * currentInstr->operand2.value;
      } else if (currentInstr->operand2.isConstant &&
                 (currentInstr->operand2.value &
                  (currentInstr->operand2.value - 1)) == 0) {
        currentInstr->opcode = IR_LSHIFT;
        currentInstr->operand2.value = log2(currentInstr->operand2.value);
      } else if (currentInstr->operand1.isConstant &&
                 (currentInstr->operand1.value &
                  (currentInstr->operand1.value - 1)) == 0) {
        currentInstr->opcode = IR_LSHIFT;
        currentInstr->operand1.value = log2(currentInstr->operand1.value);
      }
    } else if (currentInstr->opcode == IR_DIV) {
      if (currentInstr->operand2.isConstant &&
          (currentInstr->operand2.value & (currentInstr->operand2.value - 1)) ==
              0) {
        currentInstr->opcode = IR_RSHIFT;
        currentInstr->operand2.value = log2(currentInstr->operand2.value);
      }
    } else if (currentInstr->opcode == IR_MOD) {
      if (currentInstr->operand2.isConstant &&
          (currentInstr->operand2.value & (currentInstr->operand2.value - 1)) ==
              0) {
        currentInstr->opcode = IR_AND;
        currentInstr->operand2.value -= 1;
      }
    }
  }
}

void optimizeTailRecursion(IRInstruction *instructions, int numInstructions) {
  for (int i = 0; i < numInstructions; i++) {
    if (instructions[i].opcode == IR_CALL && i + 1 < numInstructions &&
        instructions[i + 1].opcode == IR_RETURN &&
        instructions[i].result.version == instructions[i + 1].result.version) {

      instructions[i].opcode = IR_RETURN;
      instructions[i].operand1 = instructions[i + 1].operand1;
      instructions[i].operand2 = instructions[i + 1].operand2;

      for (int j = i + 1; j < numInstructions - 1; j++) {
        instructions[j] = instructions[j + 1];
      }

      numInstructions--;

      i--;
    }
  }
}

bool isConstantOperand(IROperand *operand) { return operand->isConstant; }

bool isDeadInstruction(IRInstruction *instruction) {
  return instruction->isDead;
}

bool isDeadBlock(InstructionBlock *block) { return block->isAllDead; }

void updateConstantValue(IROperand *operand, IRValue newValue) {
  operand->isConstant = true;
  operand->value = newValue;
}

void killInstruction(IRInstruction *instruction) { instruction->isDead = true; }

void killBlock(InstructionBlock *block) { block->isAllDead = true; }

bool irOoperandsEqual(IROperand *irOperand1, IROperand *irOperand2) {
  if (!isConstantOperand(irOperand1) || !isConstantOperand(irOperand2)) {
    return 0;
  }

  return irOperand1->value.pointer == irOperand2->value.pointer;
}

bool ssaOperandsEqual(SSAOperand *ssaOperand1, SSAOperand *ssaOperand2) {
  return (ssaOperand1->version == ssaOperand2->version) &&
         (ssaOperand1->index == ssaOperand2->index) &&
         (ssaOperand1->value.pointer == ssaOperand2->value.pointer);
}

bool irInstructionsEqual(IRInstruction *irInstruction1,
                         IRInstruction *irInstruction2) {
  return (irInstruction1->opcode == irInstruction2->opcode) &&
         (irInstruction1->isDead == irInstruction2->isDead) &&
         ssaOperandsEqual(irInstruction1->result, irInstruction2->result) &&
         irOperandsEqual(irInstruction1->operand1, irInstruction2->operand1) &&
         irOperandsEqual(irInstruction1->operand2, irInstruction2->operand2);
}

bool phiInstructionsEqual(PhiInstruction *phiInstruction1,
                          PhiInstruction *phiInstruction2) {
  return (phiInstruction1->opcode == phiInstruction2->opcode) &&
         ssaOperandsEqual(phiInstruction1->result, phiInstruction2->result) &&
         ssaOperandsEqual(phiInstruction1->operand1,
                          phiInstruction2->operand1) &&
         ssaOperandsEqual(phiInstruction1->operand2, phiInstruction2->operand2);
}

bool instructionsEqual(Instruction *instruction1, Instruction *instruction2) {
  if ((instruction1->kind == instruction2->kind) == INST_PHI) {
    return phiInstructionsEqual(instruction1->phiInstruction,
                                instruction2->phiInstruction)
  } else
    return irInstructionsEqual(instructions1->irInstruction,
                               instruction2->irInstruction);
}

bool allInstructionsEqual(Instruction **instructions1,
                          Instruction **instructions2, int numInstructions) {
  while (--numInstructions)
           if (!instructionsEqual(instructions1[numInstructions], instructions2[numInstructions])
			   return false;
   return true;
}

bool instructionBlocksEqual(InstructionBlock *instructionBlock1,
                            InstructionBlock *instructionBlock2) {
  if (!instructionBlock1->isAllDead && !instructionBlock2->isAllDead)
    &&(instructionBlock1->numInstructions ==
       instructionBlock2->numInstructions) &&
        allInstructionsEqual(&instructionBlock1->instructions,
                             &instructionBlock2->instructions,
                             instructionBlock1->numInstructions);
}
