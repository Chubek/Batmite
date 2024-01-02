#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct DataFlowNode {
  char *name;
  struct DataFlowNode **dependencies;
  int numDependencies;
  struct DataFlowNode **dependents;
  int numDependents;
} DataFlowNode;

typedef struct {
  DataFlowNode **nodes;
  int count;
} CommonSubexpressionList;

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

void eliminateCommonSubexpressions(DataFlowNode *root) {
  if (root == NULL) {
    return;
  }

  for (int i = 0; i < root->numDependencies; ++i) {
    DataFlowNode *dependency = root->dependencies[i];
    eliminateCommonSubexpressions(dependency);
  }

  // Check if the current node represents an expression
  if (isExpressionNode(root)) {
    // Check if an identical expression exists in the dependencies
    DataFlowNode *commonNode =
        findCommonSubexpression(root, root->dependencies);

    if (commonNode != NULL) {
      // Replace the current node with the common subexpression
      replaceNodeWithCommon(root, commonNode);
    }
  }
}

CommonSubexpressionList findCommonSubexpression(DataFlowNode *graph) {
  CommonSubexpressionList commonSubexpressions = {NULL, 0};

  // Iterate through all nodes in the data flow graph
  while (graph != NULL) {
    // Check if the current node is an expression node
    if (isExpressionNode(graph)) {
      // Iterate through the list of common subexpressions
      int i;
      for (i = 0; i < commonSubexpressions.count; ++i) {
        // Check if the current node's expression matches any existing
        // subexpression
        if (expressionsMatch(graph, commonSubexpressions.nodes[i])) {
          // A common subexpression is found
          break;
        }
      }

      if (i == commonSubexpressions.count) {
        // The current node is a new common subexpression
        commonSubexpressions.nodes = (DataFlowNode **)realloc(
            commonSubexpressions.nodes,
            (commonSubexpressions.count + 1) * sizeof(DataFlowNode *));
        commonSubexpressions.nodes[commonSubexpressions.count] = graph;
        commonSubexpressions.count++;
      }
    }

    // Move to the next node in the data flow graph
    graph = getNextNode(graph);
  }

  return commonSubexpressions;
}

void replaceWithCommon(DataFlowNode *graph,
                       CommonSubexpressionList commonSubexpressions) {
  // Iterate through all nodes in the data flow graph
  while (graph != NULL) {
    // Check if the current node is an expression node
    if (isExpressionNode(graph)) {
      // Iterate through the list of common subexpressions
      for (int i = 0; i < commonSubexpressions.count; ++i) {
        // Check if the current node's expression matches any common
        // subexpression
        if (expressionsMatch(graph, commonSubexpressions.nodes[i])) {
          // Replace the current node with the common subexpression
          graph = commonSubexpressions.nodes[i];
          break;
        }
      }
    }

    // Move to the next node in the data flow graph
    graph = getNextNode(graph);
  }
}

// Function to check if two expression nodes have the same expression
int expressionsMatch(DataFlowNode *node1, DataFlowNode *node2) {
  // Check if both nodes are expression nodes
  if (!isExpressionNode(node1) || !isExpressionNode(node2)) {
    return 0; // Not expression nodes
  }

  // Assuming expressions are represented as strings
  char *expression1 = node1->name;
  char *expression2 = node2->name;

  // Perform a string comparison
  return strcmp(expression1, expression2) == 0;
}

bool isExpressionNode(DataFlowNode *node) {
  return strncmp(node->name, "_EXPR");
}
