/* Fake dlopen/dlsym shim that statically embeds 3proxy plugins.
 * StringsPlugin must be compiled with -Dstart=strings_plugin_start to avoid
 * conflicting with the "start" symbol in the 3proxy binary itself. */

#include <string.h>
#include <stdint.h>

struct pluginlink;
typedef int (*pfn)(struct pluginlink *, int, char **);

int strings_plugin_start(struct pluginlink *, int, char **);
int pcre_plugin(struct pluginlink *, int, char **);
int ssl_plugin(struct pluginlink *, int, char **);

static const struct { const char *path; const char *sym; pfn fn; } _pl[] = {
    { "StringsPlugin", "start",      (pfn)strings_plugin_start },
    { "PCREPlugin",    "pcre_plugin", (pfn)pcre_plugin          },
    { "SSLPlugin",     "ssl_plugin",  (pfn)ssl_plugin           },
    { NULL, NULL, NULL }
};

void *dlopen(const char *path, int flags) {
    (void)flags;
    if (!path) return NULL;
    for (int i = 0; _pl[i].path; i++)
        if (strstr(path, _pl[i].path)) return (void *)(uintptr_t)(i + 1);
    return NULL;
}

void *dlsym(void *handle, const char *sym) {
    int i = (int)(uintptr_t)handle - 1;
    if (i >= 0 && _pl[i].path && strcmp(_pl[i].sym, sym) == 0)
        return (void *)_pl[i].fn;
    return NULL;
}

int dlclose(void *handle) { (void)handle; return 0; }
