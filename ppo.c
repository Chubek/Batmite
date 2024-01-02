#include "ssa.h"
#include "cfg.h"

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
                            // Division by zero, handle appropriately (set result to some default value, issue a warning, etc.)
                        }
                        break;

                    case IR_MOD:
                        if (instr->irInstruction.operand2.value != 0) {
                            resultValue = instr->irInstruction.operand1.value %
                                          instr->irInstruction.operand2.value;
                        } else {
                            // Modulus by zero, handle appropriately
                        }
                        break;

                    case IR_EQ:
                        resultValue = (instr->irInstruction.operand1.value == instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_NE:
                        resultValue = (instr->irInstruction.operand1.value != instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_GT:
                        resultValue = (instr->irInstruction.operand1.value > instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_GE:
                        resultValue = (instr->irInstruction.operand1.value >= instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_LT:
                        resultValue = (instr->irInstruction.operand1.value < instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_LE:
                        resultValue = (instr->irInstruction.operand1.value <= instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_AND:
                        resultValue = (instr->irInstruction.operand1.value && instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_OR:
                        resultValue = (instr->irInstruction.operand1.value || instr->irInstruction.operand2.value) ? 1 : 0;
                        break;

                    case IR_BITWISE_AND:
                        resultValue = instr->irInstruction.operand1.value & instr->irInstruction.operand2.value;
                        break;

                    case IR_BITWISE_OR:
                        resultValue = instr->irInstruction.operand1.value | instr->irInstruction.operand2.value;
                        break;

                    case IR_BITWISE_XOR:
                        resultValue = instr->irInstruction.operand1.value ^ instr->irInstruction.operand2.value;
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
 
