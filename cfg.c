#include <stdlib.h>
#include <stdint.h>

struct BasicCFGBlock;

typedef struct {
  struct BasicCFGBlock *source;
  struct BasicCFGBlock *destination;
} CFGEdge;

typedef struct BasicCFGBlock {

  Instruction *instructions;
  int numInstructions;

  CFGEdge *successors;
  int numSuccessors;

  CFGEdge *predecessors;
  int numPredecessors;

  int blockID;
} BasicCFGBlock;

typedef struct {
  BasicCFGBlock **basicBlocks;
  int numBlocks;
} ControlFlowGraph;

BasicCFGBlock *createBasicCFGBlock(void) {
  BasicCFGBlock *block = zalloc(sizeof(BasicCFGBlock));

  block->instructions = NULL;
  block->numInstructions = 0;
  block->successors = NULL;
  block->numSuccessors = 0;
  block->predecessors = NULL;
  block->numPredecessors = 0;
  block->blockID = -1;
  return block;
}

ControlFlowGraph *createControlFlowGraph(void) {
  ControlFlowGraph *cfg = zalloc(sizeof(ControlFlowGraph));

  cfg->basicBlocks = NULL;
  cfg->numBlocks = 0;
  return cfg;
}

void addEdge(BasicCFGBlock *source, BasicCFGBlock *destination) {

  source->successors = zealloc(source->successors,
                               (source->numSuccessors + 1) * sizeof(CFGEdge));
  source->successors[source->numSuccessors]->source = source;
  source->successors[source->numSuccessors]->destination = destination;
  source->numSuccessors++;

  destination->predecessors =
      zealloc(destination->predecessors,
              (destination->numPredecessors + 1) * sizeof(CFGEdge));
  destination->predecessors[destination->numPredecessors]->source = source;
  destination->predecessors[destination->numPredecessors]->destination =
      destination;
  destination->numPredecessors++;
}

void initializeCFG(ControlFlowGraph *cfg) {
  cfg->basicBlocks = zalloc(2 * sizeof(uintptr_t));

  cfg->basicBlocks[0] = createBasicCFGBlock();
  cfg->basicBlocks[1] = createBasicCFGBlock();

  cfg->basicBlocks[0].blockID = 0;
  cfg->basicBlocks[1].blockID = 1;

  addEdge(cfg.basicBlocks[0], cfg.basicBlocks[1]);

  cfg.numBlocks = 2;
}
