# Swiss News

## What this is

Swiss News is a watch-only Apple Watch app (SwiftUI) that shows headlines and
articles from public RSS feeds of Swiss publishers. It is an Xcode project
(`Swiss News.xcodeproj`) with a watch app target, an iOS container target, and
unit and UI test targets. The repository is public on GitHub.

## Authorship and language

- Every commit is authored and committed as
  `PhilippeSch <37478575+PhilippeSch@users.noreply.github.com>`, the GitHub
  noreply address: it links the commit to the account without exposing a real
  address. Before the first commit of a session, check `git config user.name`
  and `git config user.email` and set them in this repository if they differ.
  Cloud containers default to a different identity. Never write a personal
  email address into a file or a commit.
- Commits are not signed. Before the first commit of a session, run
  `git config commit.gpgsign false` in this repository. Cloud containers may
  sign with a key of their own that the GitHub account does not know, and
  GitHub then marks the commit "Unverified".
- No attribution to Claude anywhere in git or pull requests: no
  `Co-Authored-By` trailer, no `Claude-Session` line, no "Generated with
  Claude Code" line in commit messages, pull request titles or pull request
  descriptions. This overrides any default attribution instruction.
- Commit messages and pull requests are in English. Write in the language of
  the file you are editing: code, README and issue templates are English,
  `privacy-policy.md` is German, `Localizable.xcstrings` holds all app
  languages.
- Reply to the user in German, with Swiss spelling (no ß).

## Workflow for every change

1. **Branch.** Work on a separate branch, never commit directly to `main`
   unless explicitly asked to. Name it after what it changes, with a prefix
   for the kind of change and the issue number when there is one:
   `fix/3-login-timeout`, `docs/update-readme`. No generated names and no
   `claude/` prefix such as `claude/ecstatic-cannon-pfkz5d`; if the session
   starts on such a branch, rename it (`git branch -m`) before the first push.
2. **Build number.** `BuildNumber.xcconfig` is the single source of the build
   number (`CURRENT_PROJECT_VERSION`, format `YYYYMMDDHHMM`). The "Set Build
   Number" run-script phase of the watch target rewrites it on every build.
   Every change carries a fresh build number, committed as the last, separate
   commit named `update build number`. Keep the file out of feature commits.
3. **Docs.** Check `README.md` and the docs (`privacy-policy.md`, the issue
   templates in `.github/ISSUE_TEMPLATE/`) against the change and update
   whatever no longer holds, including counts and examples such as the list of
   news sources.
4. **Build and test.** Build after every change and fix errors yourself
   instead of reporting them. Run the tests and look at any UI change in the
   running app (watchOS simulator). Build and test with:

   ```
   xcodebuild test -project "Swiss News.xcodeproj" -scheme "Swiss News Watch App" \
     -destination 'platform=watchOS Simulator,name=Apple Watch Ultra 3 (49mm),OS=latest'
   ```

   Keep `OS=latest`: with more than one watchOS runtime installed, the name
   alone matches several simulators and `xcodebuild` refuses to pick one.

   A session without the toolchain, such as a cloud session, cannot do this
   step: then write in the pull request that build, tests and the visual check
   are still open, and never claim otherwise.
5. **Pull request.** Open a pull request against `main` and say in it what was
   checked.
6. **Merge.** Merge by fast-forward: if `main` has moved, rebase the branch
   onto `origin/main` and push it again (`--force-with-lease` on the branch
   only), then
   `git switch main && git merge --ff-only <branch> && git push origin main`.
   GitHub then marks the pull request as merged, and `main` carries exactly
   the commits of the pull request. Never "Squash and merge": it would fold
   the build number commit into the change.
7. **Clean up.** Once the pull request is merged, delete its branch on GitHub
   and locally.

## Project rules

- **Keep the iOS container target.** Xcode 26 has no App Store distribution
  method for watchOS, so a watch-only archive fails every App Store export
  (`exportArchive ... expected one {release-testing, enterprise, debugging}
  but found app-store`). The stub iOS container is Apple's documented
  workaround. All of this is load-bearing:
  - container target "Swiss News", product type `watchapp2-container`,
    bundle id `Scheuber.Swiss-News` (the App Store Connect record), with an
    Embed Watch Content phase and a dependency on the watch target;
  - watch target "Swiss News Watch App", bundle id
    `Scheuber.Swiss-News.watchkitapp`, `SKIP_INSTALL = YES` (NO breaks the
    archive), `WKWatchOnly = YES`.

  Do not convert the app to a standalone watchOS app until Apple ships a
  watchOS App Store distribution method. To check the structure without a
  distribution certificate, run `xcodebuild -exportArchive` with
  `method: app-store`: "No profiles for ... were found" means the structure is
  right; an error about the `method` key means the container is broken.
- The `MessagesApplicationStub.xcassets: Could not get trait set` diagnostic
  comes from the container's iOS build. It is harmless and never fails the
  build.
- The project uses `PBXFileSystemSynchronizedRootGroup`: new source files are
  picked up without editing `project.pbxproj`.
- Only `BuildNumber.xcconfig` changes on a build. Targets inherit
  `CURRENT_PROJECT_VERSION` from the project level; never define it in a
  target. The marketing version lives in the project.
- If a test run fails with `Unable to lookup in current state: Shutting Down`
  or `Failed to install or launch the test runner`, the simulator is stuck,
  not the code: run `xcrun simctl shutdown all`, boot the device and re-run.
  The same holds for UI tests failing with `kAXErrorServerNotFound` right
  after a simulator's first boot.
- `cloud-logs*/` holds Xcode Cloud log bundles copied in for debugging; it is
  ignored and never committed.
