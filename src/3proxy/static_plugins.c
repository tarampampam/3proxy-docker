/* Fake dlopen/dlsym shim that statically embeds all 3proxy plugins.
 * Zero changes to 3proxy sources - just compile each plugin with
 * -Dstart=<unique_name> to resolve the symbol collision for StringsPlugin
 * and TrafficPlugin (both export "start"). */

#include <string.h>
#include <stdint.h>

struct pluginlink;
typedef int (*pfn)(struct pluginlink *, int, char **);

int strings_plugin_start(struct pluginlink *, int, char **);
int traffic_plugin_start(struct pluginlink *, int, char **);
int transparent_plugin(struct pluginlink *, int, char **);
int pcre_plugin(struct pluginlink *, int, char **);
int ssl_plugin(struct pluginlink *, int, char **);

static const struct { const char *path; const char *sym; pfn fn; } _pl[] = {
    { "StringsPlugin",     "start",              (pfn)strings_plugin_start },
    { "TrafficPlugin",     "start",              (pfn)traffic_plugin_start  },
    { "TransparentPlugin", "transparent_plugin", (pfn)transparent_plugin    },
    { "PCREPlugin",        "pcre_plugin",        (pfn)pcre_plugin           },
    { "SSLPlugin",         "ssl_plugin",         (pfn)ssl_plugin            },
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

char *dlerror(void) { return NULL; }
int   dlclose(void *handle) { (void)handle; return 0; }
