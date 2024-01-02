#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct InterferenceGraph {
  char *variable;
  struct InterferenceGraph **adjacentNodes;
  int numAdjacentNodes;
  int color;
  bool isPrecolored;
} InterferenceGraph;

InterferenceGraph *createInterferenceGraphNode(char *variable,
                                               bool isPrecolored) {
  InterferenceGraph *node =
      (InterferenceGraph *)malloc(sizeof(InterferenceGraph));
  node->variable = variable;
  node->adjacentNodes = NULL;
  node->numAdjacentNodes = 0;
  node->color = -1;
  node->isPrecolored = isPrecolored;
  return node;
}

void addInterference(InterferenceGraph *node1, InterferenceGraph *node2) {
  node1->adjacentNodes = (InterferenceGraph **)realloc(
      node1->adjacentNodes,
      (node1->numAdjacentNodes + 1) * sizeof(InterferenceGraph *));
  node1->adjacentNodes[node1->numAdjacentNodes] = node2;
  node1->numAdjacentNodes++;

  node2->adjacentNodes = (InterferenceGraph **)realloc(
      node2->adjacentNodes,
      (node2->numAdjacentNodes + 1) * sizeof(InterferenceGraph *));
  node2->adjacentNodes[node2->numAdjacentNodes] = node1;
  node2->numAdjacentNodes++;
}

void removeInterference(InterferenceGraph *node1, InterferenceGraph *node2) {
  for (int i = 0; i < node1->numAdjacentNodes; i++) {
    if (node1->adjacentNodes[i] == node2) {
      for (int j = i; j < node1->numAdjacentNodes - 1; j++) {
        node1->adjacentNodes[j] = node1->adjacentNodes[j + 1];
      }
      node1->numAdjacentNodes--;
      break;
    }
  }

  for (int i = 0; i < node2->numAdjacentNodes; i++) {
    if (node2->adjacentNodes[i] == node1) {
      for (int j = i; j < node2->numAdjacentNodes - 1; j++) {
        node2->adjacentNodes[j] = node2->adjacentNodes[j + 1];
      }
      node2->numAdjacentNodes--;
      break;
    }
  }
}

bool canCoalesce(InterferenceGraph *node1, InterferenceGraph *node2,
                 int numRegisters) {
  return (!node1->isPrecolored && !node2->isPrecolored &&
          node1->numAdjacentNodes + node2->numAdjacentNodes < numRegisters &&
          !areNodesAdjacent(node1, node2) &&
          !areNodesInterfering(node1, node2));
}

void coalesceNodes(InterferenceGraph *node1, InterferenceGraph *node2) {
  for (int i = 0; i < node2->numAdjacentNodes; i++) {
    InterferenceGraph *adjacentNode = node2->adjacentNodes[i];
    removeInterference(node1, adjacentNode);
    removeInterference(adjacentNode, node1);
    addInterference(node1, adjacentNode);
    addInterference(adjacentNode, node1);
  }
}

int getNextAvailableColor(InterferenceGraph *node, int numRegisters) {
  int *colorUsed = (int *)calloc(numRegisters, sizeof(int));

  for (int i = 0; i < node->numAdjacentNodes; i++) {
    InterferenceGraph *adjacentNode = node->adjacentNodes[i];
    if (adjacentNode->color != -1) {
      colorUsed[adjacentNode->color] = 1;
    }
  }

  int nextAvailableColor = 0;
  while (colorUsed[nextAvailableColor]) {
    nextAvailableColor++;
  }

  free(colorUsed);
  return nextAvailableColor;
}

void graphColoring(InterferenceGraph *interferenceGraph, int numRegisters) {
  while (interferenceGraph) {
    InterferenceGraph *currentNode = interferenceGraph;

    while (currentNode && currentNode->color != -1) {
      currentNode = currentNode->adjacentNodes[0];
    }

    if (!currentNode) {
      break;
    }

    currentNode->color = getNextAvailableColor(currentNode, numRegisters);

    for (int i = 0; i < currentNode->numAdjacentNodes; i++) {
      InterferenceGraph *adjacentNode = currentNode->adjacentNodes[i];
      if (adjacentNode->color == -1) {
        adjacentNode->color = getNextAvailableColor(adjacentNode, numRegisters);
      }
    }
  }
}

bool needsSpill(InterferenceGraph *node, int numRegisters) {
  return (node->color == -1 && node->numAdjacentNodes >= numRegisters);
}

InterferenceGraph *spillChecking(InterferenceGraph *interferenceGraph,
                                 int numRegisters) {
  InterferenceGraph *currentNode = interferenceGraph;
  InterferenceGraph *nextNode = NULL;

  while (currentNode) {
    if (needsSpill(currentNode, numRegisters)) {

      currentNode->color = -2;
    }

    nextNode = currentNode->adjacentNodes[0];
    currentNode = nextNode;
  }

  return nextNode;
}

void graphColoringWithSpill(InterferenceGraph *interferenceGraph,
                            int numRegisters) {
  while (interferenceGraph) {
    InterferenceGraph *currentNode = interferenceGraph;

    while (currentNode && currentNode->color != -1) {
      currentNode = currentNode->adjacentNodes[0];
    }

    if (!currentNode) {
      break;
    }

    currentNode->color = getNextAvailableColor(currentNode, numRegisters);

    for (int i = 0; i < currentNode->numAdjacentNodes; i++) {
      InterferenceGraph *adjacentNode = currentNode->adjacentNodes[i];
      if (adjacentNode->color == -1) {
        adjacentNode->color = getNextAvailableColor(adjacentNode, numRegisters);
      }
    }

    void coalesceAndColor(InterferenceGraph * interferenceGraph,
                          int numRegisters) {
      while (interferenceGraph) {
        InterferenceGraph *currentNode = interferenceGraph;

        while (currentNode) {
          for (int i = 0; i < currentNode->numAdjacentNodes; i++) {
            InterferenceGraph *adjacentNode = currentNode->adjacentNodes[i];
            if (canCoalesce(currentNode, adjacentNode, numRegisters)) {
              coalesceNodes(currentNode, adjacentNode);
              currentNode = interferenceGraph;
              break;
            }
          }
          currentNode = currentNode->adjacentNodes[0];
        }
      }

      graphColoring(interferenceGraph, numRegisters);
    }

    bool areNodesAdjacent(InterferenceGraph * node1,
                          InterferenceGraph * node2) {
      for (int i = ; i < node1->numAdjacentNodes; i++) {
        if (node1->adjacentNodes[i] == node2) {
          return true;
        }
      }
      return false;
    }

    bool areNodesInterfering(InterferenceGraph * node1,
                             InterferenceGraph * node2) {
      return (node1->color != -1 && node2->color != -1 &&
              node1->color == node2->color);
    }

    bool areNodesAdjacent(InterferenceGraph * node1,
                          InterferenceGraph * node2) {
      for (int i = 0; i < node1->numAdjacentNodes; i++) {
        if (node1->adjacentNodes[i] == node2) {
          return true;
        }
      }
      return false;
    }

    bool areNodesInterfering(InterferenceGraph * node1,
                             InterferenceGraph * node2) {
      return (node1->color != -1 && node2->color != -1 &&
              node1->color == node2->color);
    }
