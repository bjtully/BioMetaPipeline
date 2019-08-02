#include <cstdlib>
#include <string>
const int LEAF_LEN = 4;

struct Rope_node {
    Rope_node *left, *right, *parent;
    char *str;
    int lCount;
};

class Rope {
    public:
        Rope();
        Rope(std::string);
        ~Rope();
        void create(std::string);
        std::string to_string();
        size_t size();
        void append(Rope&);
        void append(std::string);
    private:
        Rope_node *root;
        size_t strSize;

        static void clearRoot(Rope_node *r) {
            if (r == NULL) return;
            if (r->left == NULL && r->right == NULL) {
                delete r->str;
            }
            Rope::clearRoot(r->left);
            Rope::clearRoot(r->right);
        }
        
        static void rootToString(Rope_node *r, char *value, int i) {
            if (r == NULL) return;
            if (r->left == NULL && r->right == NULL) {
                // Size of stored string
                int stSz = sizeof(r->str) / sizeof(r->str[0]);
                // Copy to pointer
                for (int j = 0; j < stSz; j++) {
                    value[i + j] = r->str[j];
                }
                // Update location in string
                i += r->lCount + 1;
            }
            Rope::rootToString(r->left, value, i);
            // Update location in string
            i += r->lCount + 1;
            Rope::rootToString(r->right, value, i);
        }

        static void ropify_value(std::string value, Rope_node *&node, Rope_node *par,
                                    int l, int r) {
            Rope_node *tmp = new Rope_node();
            tmp->left = tmp->right = NULL;
            tmp->parent = par;

            // Long string
            if ((r - l) > LEAF_LEN) {
                tmp->str = NULL;
                // 1/2 of nodes in left subtree
                tmp->lCount = (r - l) / 2;
                // Store node
                node = tmp;
                // Middle location
                int m = (l + r) / 2;
                // Split at middle, recursive call until short string
                Rope::ropify_value(value, node->left, node, l, m);
                Rope::ropify_value(value, node->right, node, m + 1, r);
            }
            // Short string
            else {
                node = tmp;
                tmp->lCount = (r - l);
                int j = 0;
                // Declare memory
                tmp->str = new char[LEAF_LEN];
                for (int i = l; i <= r; i++) {
                    tmp->str[j++] = value[i];
                }
            }
        }
};
