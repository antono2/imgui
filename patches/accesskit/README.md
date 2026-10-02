# AccessKit compatibility patches

Pinned release: AccessKit C 0.23.1. The preparation script verifies the release
archive and patched crates against their published SHA-256 checksums.
The original MIT/Apache licensing remains in the downloaded packages.

`linux-atspi.patch` currently fixes two issues found by the 100,000-row AT-SPI test:

* AddAccessible and RemoveAccessible require a single struct argument. Wrapping
  the payload in a one-element tuple preserves that D-Bus signature when zbus
  serializes method arguments. Without it, libatspi 2.52 rejects cache signals.
* Building each cache entry previously traversed all preceding filtered siblings.
  A context cache enumerates a parent's filtered children once and reuses their
  indices. It is invalidated under the tree write lock on updates.

`cargo-lock.patch` changes the two package entries to local patched sources while
preserving the release's remaining locked dependencies. No patches have been
submitted upstream yet. Revisit/remove these patches when a pinned upstream
release provides equivalent fixes. Run the real AT-SPI test before changing them;
a retained-tree unit test alone does not exercise D-Bus serialization or exporting
large sibling lists.

`android-set-text.patch` adds Android's `ACTION_SET_TEXT` to editable text nodes,
decodes the replacement `CharSequence`, and forwards a `SetValue` action. The
pinned Android adapter previously supported selection and numeric value changes
but omitted text replacement. `android-cargo-lock.patch` selects the verified
local source without updating other dependencies. `--android-source` prepares
this patch; `scripts/test_android_accessible.sh` checks it through Android's real
accessibility API. This patch has not been submitted upstream.

`linux-focus-cache.patch` invalidates filtered sibling indexes when host focus
changes, since focused off-screen rows bypass clipping. Stale queries for rows
that are no longer exposed return Defunct instead of aborting the application.
