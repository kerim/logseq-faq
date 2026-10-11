/*
 * Passthrough launcher for the logseq-faq-publish LaunchAgent.
 *
 * macOS refuses to let launchd run a user-directory script directly, and
 * names a background job in Login Items & Extensions after the file at
 * ProgramArguments[0]. Compiling this under the job's own name
 * (watch/install.sh does it) satisfies both: it is a real binary, and the
 * job shows up as "logseq-faq-publish" instead of "bash".
 *
 * It only execs the command given as its arguments. It is safe because it is
 * not setuid and its arguments come from the plist alone; keep it that way.
 */
#include <errno.h>
#include <libgen.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    const char *self = (argc > 0 && argv[0] != NULL) ? argv[0] : "launcher";
    if (argc < 2) {
        fprintf(stderr, "usage: %s <absolute-command> [args...]\n", self);
        return 2;
    }
    char selfcopy[1024];
    snprintf(selfcopy, sizeof selfcopy, "%s", self);
    char *name = basename(selfcopy);

    char *command = argv[1];
    argv[1] = name;
    execv(command, &argv[1]);

    fprintf(stderr, "%s: cannot exec %s: %s\n", name, command, strerror(errno));
    return 127;
}
