#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

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

void *zAlloc(ZHeap *zheap, size_t size) {
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

void *zRealloc(ZHeap *zheap, void *memory, size_t new_size) {
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

char* template_string(const char* template, ...) {
    va_list args;
    va_start(args, template);

    
    size_t len = 0;
    const char* ptr = template;
    while (*ptr) {
        if (*ptr == '{' && *(ptr + 1) == '}') {            
            ptr += 2;            
            len += strlen(va_arg(args, const char*));
        } else {            
            len++;
            ptr++;
        }
    }

    
    char* result = (char*)malloc(len + 1);
    if (!result) {
        fprintf(stderr, "Memory allocation error\n");
        va_end(args);
        return NULL;
    }

    
    char* dest = result;
    ptr = template;
    while (*ptr) {
        if (*ptr == '{' && *(ptr + 1) == '}') {            
            const char* arg = va_arg(args, const char*);
            size_t arg_len = strlen(arg);
            zMemCopy(dest, arg, arg_len);
            dest += arg_len;
            ptr += 2; 
        } else {            
            *dest = *ptr;
            dest++;
            ptr++;
        }
    }

    *dest = '\0'; 
    va_end(args);
    return result;
}

