#include <stdlib.h>
#include <stdint.h>

struct CFGBlock;

typedef struct {
  struct CFGBlock *source;
  struct CFGBlock *destination;
} CFGEdge;

typedef struct CFGBlock {

  Instruction *instructions;
  int numInstructions;

  CFGEdge *successors;
  int numSuccessors;

  CFGEdge *predecessors;
  int numPredecessors;

  int blockID;
} CFGBlock;

typedef struct {
  CFGBlock **basicBlocks;
  int numBlocks;
} ControlFlowGraph;

CFGBlock *createCFGBlock(void) {
  CFGBlock *block = zalloc(sizeof(CFGBlock));

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

void addEdge(CFGBlock *source, CFGBlock *destination) {

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

  cfg->basicBlocks[0] = createCFGBlock();
  cfg->basicBlocks[1] = createCFGBlock();

  cfg->basicBlocks[0].blockID = 0;
  cfg->basicBlocks[1].blockID = 1;

  addEdge(cfg.basicBlocks[0], cfg.basicBlocks[1]);

  cfg.numBlocks = 2;
}
