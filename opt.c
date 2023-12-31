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
