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

typedef struct Node {
   enum {
	UQUAD,
	QUAD,
	UDOUBLE,
	DOBULE,
	UHALF,
	HALF,
	UBYTE,
	BYTE,
	POINTER,
   } kind;
   union {
	unsigned long unsignedQuad;
	long signedQuad;
	unsigned int unsignedDouble;
	int signedDouble;
	unsigned short unsignedHalf;
	short signedHalf;
	unsigned char unsignedByte;
	char signedByte;
	void* pointer;
    };
    struct Node *next;
} Node;


typedef struct {
    Node *localVariables;  
    Node *parameters;      
    long returnAddress;
    long stackPointer;;
} ActivationRecord;

SSAOperand createSSAOperand(int version, int index) {
    SSAOperand operand;
    operand.version = version;
    operand.index = index;
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


Instruction createInstruction(InstructionKind kind, PhiInstruction phiInstr, IRInstruction irInstr) {
    Instruction instruction;
    instruction.kind = kind;
    
    if (kind == INST_PHI) {
        instruction.phiInstruction = phiInstr;
    } else {
        instruction.irInstruction = irInstr;
    }
    
    return instruction;
}


InstructionBlock createInstructionBlock(Instruction *instructions, CFGBlock *cfgBlock, int numInstructions) {
    InstructionBlock block;
    block.instructions = instructions;
    block.cfgBlock = cfgBlock;
    block.numInstructions = numInstructions;
    return block;
}


IRFunction createIRFunction(InstructionBlock *instructionBlocks, CFGBlock *entryCFGBlock, int numBlocks) {
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

Node* insert(Node *head, int data) {
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
