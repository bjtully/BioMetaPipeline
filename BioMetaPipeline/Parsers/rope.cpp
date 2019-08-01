#include "rope.h"

// Rope data structure adapted from 
// https://www.geeksforgeeks.org/ropes-data-structure-fast-string-concatenation/

Rope::Rope() {
    strSize = 0;
}

Rope::Rope(std::string initial) {
    strSize = initial.size();
    // Copies initial value, as Rope, to stored pointer to root Rope_node
    Rope::ropify_value(initial, root, NULL, 0, (int)initial.size() - 1);
}

Rope::~Rope() {
    Rope::clearRoot(root);
}

void Rope::create(std::string initial) {
    strSize = initial.size();
    // Copies initial value, as Rope, to stored pointer to root Rope_node
    Rope::ropify_value(initial, root, NULL, 0, (int)initial.size() - 1);
}

std::string Rope::to_string() {
    char value[strSize + 1];
    // Pre-reserve string size
    std::string toReturn;
    // toReturn.reserve(strSize + 1);
    Rope::rootToString(root, value, 0);
    toReturn = value;
    return toReturn;
}

size_t Rope::size() {
    return strSize;
}

void Rope::append(Rope &other) {
    Rope_node *newRoot = new Rope_node();
    newRoot->parent = NULL;
    newRoot->str = NULL;
    newRoot->left = root;
    newRoot->right = other.root;
    newRoot->lCount = strSize - 1;
    root->parent = newRoot;
    other.root->parent = newRoot;
    strSize += other.size();
    root = newRoot;
}

void Rope::append(std::string str1) {
    Rope_node *newRoot = new Rope_node();
    Rope *other = new Rope(str1);
    newRoot->parent = NULL;
    newRoot->str = NULL;
    newRoot->left = root;
    newRoot->right = other->root;
    newRoot->lCount = strSize - 1;
    root->parent = newRoot;
    other->root->parent = newRoot;
    strSize += other->size();
    root = newRoot;
}
