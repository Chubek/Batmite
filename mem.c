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

struct {
  void *data;
  Node *next;
  uint32_t hash;
};

struct {
  Node *head;
};

void initZHeap(ZHeap *zheap) { zheap->head = NULL; }

void *zalloc(ZHeap *zheap, size_t size) {
  Node *newNode = (Node *)calloc(1, sizeof(Node));
  if (!newNode) {
    fprintf(stderr, "Memory allocation failed\n");
    exit(EXIT_FAILURE);
  }

  newNode->data = calloc(1, size);
  if (!newNode->data) {
    fprintf(stderr, "Memory allocation failed\n");
    exit(EXIT_FAILURE);
  }
  newNode->hash = hashPointer(newNode->data);

  newNode->next = zheap->head;
  zheap->head = newNode;

  return newNode->data;
}

void *zealloc(ZHeap *zheap, void *memory, size_t new_size) {
  Node *currentNode = zhead->head;
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
  Node *current = zheap->head;

  while (current != NULL) {
    Node *next = current->next;
    free(current->data);
    free(current);
    current = next;
  }

  zheap->head = NULL;
}
