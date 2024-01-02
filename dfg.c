#include <stdio.h>
#include <stdlib.h>

typedef struct DataFlowNode {
  char *name;
  struct DataFlowNode **dependencies;
  int numDependencies;
  struct DataFlowNode **dependents;
  int numDependents;
} DataFlowNode;

DataFlowNode *createDataFlowNode(char *name) {
  DataFlowNode *node = (DataFlowNode *)zalloc(sizeof(DataFlowNode));
  node->name = name;
  node->dependencies = NULL;
  node->numDependencies = 0;
  node->dependents = NULL;
  node->numDependents = 0;
  return node;
}

void addDependency(DataFlowNode *dependent, DataFlowNode *dependency) {
  dependent->dependencies = (DataFlowNode **)zealloc(
      dependent->dependencies,
      (dependent->numDependencies + 1) * sizeof(DataFlowNode *));
  dependent->dependencies[dependent->numDependencies] = dependency;
  dependent->numDependencies++;

  dependency->dependents = (DataFlowNode **)zealloc(
      dependency->dependents,
      (dependency->numDependents + 1) * sizeof(DataFlowNode *));
  dependency->dependents[dependency->numDependents] = dependent;
  dependency->numDependents++;
}
