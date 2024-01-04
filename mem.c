#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

uint32_t hashPointer(const void *key) {
  const uint8_t *p = (const uint8_t *)key;
  uint32_t hash = 0;

  while (*p != '\0') {
    hash += *p++;
    hash += (hash << 10);
    hash ^= (hash >> 6);
  }

  hash += (hash << 3);
  hash ^= (hash >> 11);
  hash += (hash << 15);

  return hash;
}

typedef struct {
  void *data;
  ZNode *next;
  uint32_t hash;
} ZNode;

struct {
  ZNode *head;
};

void initZHeap(ZHeap *zheap) { zheap->head = NULL; }

void *zalloc(ZHeap *zheap, size_t size) {
  ZNode *newZNode = (ZNode *)calloc(1, sizeof(ZNode));
  if (!newZNode) {
    fprintf(stderr, "Memory allocation failed\n");
    exit(EXIT_FAILURE);
  }

  newZNode->data = calloc(1, size);
  if (!newZNode->data) {
    fprintf(stderr, "Memory allocation failed\n");
    exit(EXIT_FAILURE);
  }
  newZNode->hash = hashPointer(newZNode->data);

  newZNode->next = zheap->head;
  zheap->head = newZNode;

  return newZNode->data;
}

void *zealloc(ZHeap *zheap, void *memory, size_t new_size) {
  ZNode *currentZNode = zhead->head;
  uint32_t searchHash = hashPointer(memory);

  while (current != NULL && searchHash != current->hash)
    current = current->next;

  if (curent == NULL) {
    fprintf(stderr, "Memory pointer non-existent\n");
    exit(EXIT_FAILURE);
  }

  current->data = realloc(current->data, new_size);
  if (current->data == NULL) {
    fprintf(stderr, "Memory reallocation failed\n");
    exit(EXIT_FAILURE);
  }

  return current->data;
}

void zfree(ZHeap *zheap) {
  ZNode *current = zheap->head;

  while (current != NULL) {
    ZNode *next = current->next;
    free(current->data);
    free(current);
    current = next;
  }

  zheap->head = NULL;
}
