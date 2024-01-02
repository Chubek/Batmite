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
    void *pointer;
  };
} IRValue;

typedef enum {
  IR_ADD,
  IR_SUB,
  IR_MUL,
  IR_DIV,
  IR_MOD,
  IR_NEG,
  IR_AND,
  IR_OR,
  IR_XOR,
  IR_NOT,
  IR_LSHIFT,
  IR_RSHIFT,
  IR_LT,
  IR_LE,
  IR_GT,
  IR_GE,
  IR_EQ,
  IR_NE,
  IR_GOTO,
  IR_IF,
  IR_LABEL,
  IR_RETURN,
  IR_CALL,
  IR_PARAM,
  IR_NOP,
  IR_CAST,
  IR_SWITCH,
  IR_CASE,
  IR_DEFAULT,
  IR_BREAK,
  IR_CONTINUE,
  IR_DO_WHILE,
  IR_WHILE,
  IR_FOR,
  IR_PHI,
  IR_ASSIGN,
  IR_LOAD,
  IR_STORE,
} IROpcode;

typedef struct {
  int isConstant;
  IRValue value;
} IROperand;

typedef struct {
  int version;
  int index;
  IROperand *irValue;
} SSAOperand;

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
      // Check if the operands are constants or powers of two
      if (currentInstr->operand1.isConstant &&
          currentInstr->operand2.isConstant) {
        // Replace multiplication with addition of constants
        currentInstr->opcode = IR_ADD;
        currentInstr->result.irValue->value =
            currentInstr->operand1.value * currentInstr->operand2.value;
      } else if (currentInstr->operand2.isConstant &&
                 (currentInstr->operand2.value &
                  (currentInstr->operand2.value - 1)) == 0) {
        // Operand2 is a power of two, replace multiplication with left shift
        currentInstr->opcode = IR_LSHIFT;
        currentInstr->operand2.value = log2(currentInstr->operand2.value);
      } else if (currentInstr->operand1.isConstant &&
                 (currentInstr->operand1.value &
                  (currentInstr->operand1.value - 1)) == 0) {
        // Operand1 is a power of two, replace multiplication with left shift
        currentInstr->opcode = IR_LSHIFT;
        currentInstr->operand1.value = log2(currentInstr->operand1.value);
      }
    } else if (currentInstr->opcode == IR_DIV) {
      // Check if the divisor is a power of two
      if (currentInstr->operand2.isConstant &&
          (currentInstr->operand2.value & (currentInstr->operand2.value - 1)) ==
              0) {
        // Operand2 is a power of two, replace division with right shift
        currentInstr->opcode = IR_RSHIFT;
        currentInstr->operand2.value = log2(currentInstr->operand2.value);
      }
    } else if (currentInstr->opcode == IR_MOD) {
      // Check if the divisor is a power of two
      if (currentInstr->operand2.isConstant &&
          (currentInstr->operand2.value & (currentInstr->operand2.value - 1)) ==
              0) {
        // Operand2 is a power of two, replace modulus with bitwise AND
        currentInstr->opcode = IR_AND;
        currentInstr->operand2.value -= 1; // Subtract 1 to create a bitmask
      }
    }
  }
}
