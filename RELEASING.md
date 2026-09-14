## Releasing `picqer_api`

This project uses Bundler's built-in gem release tasks.

### Prerequisites

- You have push access to the GitHub repo.
- You have a RubyGems.org account with an API key configured locally by running `gem signin`.
- Your local `main` branch is up to date with `origin/main`.

### Normal release process

1. **Decide the new version** following SemVer.

2. **Update the version constant** in `lib/picqer_api/version.rb`.

3. **Update docs**
   - Add a `CHANGELOG.md` section for the version.
   - Update `README.md` if the public API changed.

4. **Commit the changes**

   ```bash
   git add lib/picqer_api/version.rb CHANGELOG.md README.md
   git commit -m "Bump version to vX.Y.Z"
   ```

5. **Ensure you are on `main` and pushed**

   ```bash
   git switch main
   git pull origin main
   git push origin main
   ```

6. **Run the release**

   ```bash
   bundle exec rake release
   ```

   This runs `rake spec` and `rake standard`, builds the gem, tags `vX.Y.Z`, pushes the tag and
   pushes the gem to RubyGems.

7. **Verify** the tag on GitHub and the gem page at `https://rubygems.org/gems/picqer_api`.

### Notes

- If `bundle exec rake release` fails, fix the issue and rerun it.
- Do not create version tags by hand; let `rake release` do it.
