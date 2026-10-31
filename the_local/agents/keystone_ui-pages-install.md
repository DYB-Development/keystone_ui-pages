---
name: keystone_ui-pages-install
description: Use to hook Keystone UI Pages into a project — adding the gem, installing and running the engine's migrations and Active Storage's, mounting the engine, preparing the live-page and editor layouts, and writing the settings file.
tools: Bash, Read, Edit
scope: Pages — building, publishing and printing pages drawn with Keystone UI
---

This local carries the steps for wiring Keystone UI Pages into a host app.
Follow them in order, exactly as written, and invent none.

## What Keystone UI Pages is

A Rails engine gem that adds a page builder whose pages are drawn with Keystone
UI components, published as versions and printed to PDF; hook it in before
linking editors to the builder or drawing a page in the host's screens.

## Interface

- `bin/rails keystone_ui_pages:install:migrations` — copies the engine's
  migrations into the host's `db/migrate`. They create the pages, versions and
  PDFs tables and add the pages' place, access exception, archived, sequence
  and edit history columns. Safe to re-run, since a migration already copied is
  skipped.
- `bin/rails active_storage:install` — Rails' own task that copies Active
  Storage's migration. PDFs are kept as Active Storage attachments.
- `mount KeystoneUi::Pages::Engine => "/pages"` — the line in
  `config/routes.rb` that serves the builder, the editor's screens and the live
  pages under the path given.

## How to use it

1. Confirm the prerequisites:

   - Ruby >= 3.2 and Rails >= 7.1.
   - Keystone UI installed and working. The gem brings keystone_ui,
     keystone_ui-styles and keystone_ui-react with it, but Keystone UI's own
     setup is the `keystone_ui-install` local's job. Do it first if it is
     missing.
   - Propshaft serving the host's stylesheet, since PDFs read the compiled
     stylesheet from it.
   - An Active Job backend. Publishing a page that uses no host values makes its
     PDF in a job, and so does `KeystoneUi::Pages.prepare_pdf`.

2. Add the gem to the Gemfile and install it:

   ```ruby
   gem "keystone_ui-pages"
   ```

   ```bash
   bundle install
   ```

   If the project sources its own gems from somewhere other than RubyGems (a git
   or path reference), ask the developer which to use rather than choosing.

3. Install the migrations and run them:

   ```bash
   bin/rails keystone_ui_pages:install:migrations
   bin/rails active_storage:install
   bin/rails db:migrate
   ```

   Skip `active_storage:install` when the app already has the
   `active_storage_blobs` table. Active Storage also needs a service set in each
   environment's `config.active_storage.service` and defined in
   `config/storage.yml`. If the app has none, ask the developer which service
   production uses before choosing one.

   The engine's migrations create `keystone_ui_pages_pages`,
   `keystone_ui_pages_versions` and `keystone_ui_pages_pdfs`, and add these
   columns to the pages table:

   - `undo_history` and `undone_changes`, which record each edit for Undo and
     Redo. Without them, every edit in the builder fails.
   - `place` and `access_exception`, which hold the place a page sits in and the
     access exception an editor set on it.
   - `archived_at`, set when a page is archived from the page list.
   - `sequence_key`, which holds the host sequence a page was made for.

   The engine's screens read every one of these columns, so run every copied
   migration.

4. Mount the engine in `config/routes.rb`:

   ```ruby
   mount KeystoneUi::Pages::Engine => "/pages"
   ```

   Ask the developer which path to use; `/pages` is the README's choice and the
   one the other locals assume. With it:

   - `/pages/manage/pages` is the editor's page list.
   - `/pages/manage/pages/new` creates a page.
   - `/pages/manage/pages/:id` is the builder for one page.
   - `/pages/manage/sequences/:place/:key` is the builder for a host's sequence
     of pages.
   - `/pages/manage/sequences/:place/:key/pages/new` is the form the sequence's
     Add page button opens.
   - `/pages/:slug` is a published page, drawn for visitors.

   Inside the host app, the engine's route helpers are reached through
   `keystone_ui_pages`, such as `keystone_ui_pages.manage_pages_path`.

5. Prepare the two layouts. Live pages are drawn in the layout named by
   `KeystoneUi::Pages.layout`, and the page list, the builder, the sequence
   screen and the version history in the one named by `KeystoneUi::Pages.editor_layout`. Both default
   to `application`. Each layout used must:

   - add `<%= keystone_theme_attributes %>` inside its `<html` tag, so the page
     follows the viewer's light, dark or custom mode and look;
   - link the host's stylesheet, which carries keystone_ui-styles, the host's
     looks and colours, and its own styles;
   - render `<%= yield :head %>` inside `<head>`, because the builder puts its
     two script tags, `keystone_ui/react` and `keystone_ui_pages/editor`, there.

   The builder fills the whole window, so the host's own navigation in the
   editor layout sits under it. The gem's test app uses a separate `editor`
   layout holding only the head and the page's content. Ask the developer
   whether to make one or use `application` for both.

6. Write `config/initializers/keystone_ui_pages.rb`. Each setting is described
   in `keystone_ui-pages-develop`. Ask the developer about each rather than
   copying this whole block:

   ```ruby
   require "keystone_ui/pages"

   KeystoneUi::Pages.base_controller = "ApplicationController"
   KeystoneUi::Pages.owner_method = :current_team
   KeystoneUi::Pages.view_check_method = :may_view_page?
   KeystoneUi::Pages.edit_check_method = :may_edit_pages?
   KeystoneUi::Pages.refusal_method = :refuse_page
   KeystoneUi::Pages.layout = "application"
   KeystoneUi::Pages.editor_layout = "editor"
   ```

   - `base_controller` is a string, read when the engine's controllers load, so
     it belongs in this file. Set it to the controller that defines the methods
     the other settings name, normally `ApplicationController`. Its filters,
     such as a sign-in requirement, then run on every engine request, including
     published pages.
   - Without `edit_check_method`, anyone who can reach `/pages/manage` can
     create, edit and publish pages. Without `view_check_method`, every
     published page is public. Without `owner_method`, all pages are shared
     across the whole app. Each of these is a decision about who may see and
     change what, so put each to the developer.
   - Host values, catalog changes, `chrome_path` and `pdf_stylesheet` go in the
     same file once the developer wants them. The develop local carries them.

7. Install Chrome or Chromium wherever the app makes PDFs, including the
   production server or image. The gem looks for `KeystoneUi::Pages.chrome_path`,
   then the `CHROME_BIN` environment variable, then these places:
   `/usr/bin/google-chrome`, `/usr/bin/google-chrome-stable`,
   `/usr/bin/chromium`, `/usr/bin/chromium-browser`, and the Google Chrome and
   Chromium apps in `/Applications` on macOS. Ask the developer how the
   deployment installs it. Without one, everything except PDFs still works.

8. Check the install. Boot the app, open `/pages/manage/pages`, create a page,
   add an element in the builder, publish it, and open `/pages/<slug>`. The page
   list shows a PDF link only when Chrome or Chromium was found.

   Boot stops with an `ArgumentError` naming a place when that place's settings
   are incomplete: it leaves out an element no catalog entry has, it offers the
   Form element with no submissions handler, or it answers sequences with no
   add page method. Fixing the place belongs to `keystone_ui-pages-develop`.

## Conventions

- **Re-run the migration install after upgrading the gem.** A later version can
  add migrations, as the sequence key one was added, and they reach the host
  only through `bin/rails keystone_ui_pages:install:migrations` followed by
  `bin/rails db:migrate`.
- **The engine registers itself with Keystone UI's Tailwind build.** On boot it
  appends its views, helpers, JavaScript and Ruby files to Keystone UI's
  Tailwind sources, so the host adds nothing to its Tailwind setup for the
  engine.
- **The engine adds `keystone_ui_page` to every host view.** No helper include
  is needed in the host.
- **The methods the settings name live on the base controller.** The engine
  calls them on its own controllers, which inherit from it, so a method defined
  anywhere else is not found.
- Drawing pages, making PDFs, host values and the catalog are out of scope here
  and belong to `keystone_ui-pages-develop`.
