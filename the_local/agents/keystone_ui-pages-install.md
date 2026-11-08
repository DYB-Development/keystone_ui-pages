---
name: keystone_ui-pages-install
description: Use to hook Keystone UI Pages into a project — adding the gem, installing and running the engine's migrations and Active Storage's, mounting the engine, preparing the live-page and editor layouts, choosing how PDFs are made, and starting the settings file.
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
  PDFs tables and add the pages' edit history, place, access exception,
  archived and sequence columns. Safe to re-run, since a migration already
  copied is skipped.
- `bin/rails active_storage:install` — Rails' own task that copies Active
  Storage's migration. PDFs are kept as Active Storage attachments.
- `mount KeystoneUi::Pages::Engine => "/pages"` — the line in
  `config/routes.rb` that serves the builder, the editor's screens and the live
  pages under the path given.

## How to use it

1. Confirm the prerequisites:

   - Ruby >= 3.2 and Rails >= 7.1.
   - Keystone UI installed and working. The gem brings keystone_ui,
     keystone_ui-styles, keystone_ui-react and prawn with it, but Keystone UI's
     own setup is the `keystone_ui-install` local's job. Do it first if it is
     missing.
   - An Active Job backend. Publishing a page that uses no host values makes its
     PDF in a job.
   - An error reporter subscribed to `Rails.error`, such as the one Sentry,
     Honeybadger or AppSignal installs. A PDF refused while publishing or while
     being made ahead of time does not stop the publish, and is reported only
     through `Rails.error` with the page's id and name. With no subscriber, that
     refusal is seen by nobody. If the app has none, ask the developer which
     service to use rather than choosing one.

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

   Ask the developer which path to use. `/pages` is the README's choice and the
   one the other locals assume. Under it the engine serves the editor's page
   list, the builder for one page, the builder for a host's sequence of pages,
   the version history, and each published page at `/pages/<slug>`.

   Inside the host app, the engine's route helpers are reached through
   `keystone_ui_pages`, such as `keystone_ui_pages.manage_pages_path` for the
   page list.

5. Prepare the two layouts. Live pages are drawn in one layout, and the page
   list, the builder, the sequence screen and the version history in another.
   Both default to `application`. Each layout used must:

   - add `<%= keystone_theme_attributes %>` inside its `<html` tag, so the page
     follows the viewer's light, dark or custom mode and look;
   - link the host's stylesheet, which carries keystone_ui-styles, the host's
     looks and colours, and its own styles;
   - render `<%= yield :head %>` inside `<head>`, because the builder puts its
     two script tags, `keystone_ui/react` and `keystone_ui_pages/editor`, there.

   The builder fills the whole window, so the host's own navigation in the
   editor's layout sits under it. The gem's test app uses a separate `editor`
   layout holding only the head and the page's content. Ask the developer
   whether to make one or use `application` for both.

6. Choose how PDFs are made, and ask the developer which one:

   - **Chrome, the default.** Chrome or Chromium on the server prints the page
     from the host's compiled stylesheet, so the PDF looks as the page does.
     It needs Chrome or Chromium installed wherever the app makes PDFs,
     including the production server or image, and Propshaft serving the
     host's stylesheet. The gem uses the path the settings file names, then the
     `CHROME_BIN` environment variable, then the first of
     `/usr/bin/google-chrome`, `/usr/bin/google-chrome-stable`,
     `/usr/bin/chromium`, `/usr/bin/chromium-browser`, and the Google Chrome and
     Chromium apps in `/Applications` on macOS. Ask the developer how the
     deployment installs it. Without one, everything except PDFs still works,
     and a PDF asked for is refused with a message saying how to name a
     browser.
   - **Ruby.** The gem draws the PDF with Prawn from the page's sections, rows,
     columns and elements, so no browser is needed. The heading, label,
     paragraph, alert, label and value list, button, accordion and table
     elements print. The form, copy button and Next page elements are left out of the
     PDF. A PDF of a page holding any other element is refused with a message
     naming that element. Ask the developer whether the pages they plan
     to print hold only those elements before choosing this drawing.
     It still needs Propshaft serving the host's stylesheet, since it reads the
     fonts, weights, text colours, fills, borders, radii and spacing from its
     `--ks-` tokens, the page's line height from its `html` rule, and the text
     sizes, line heights and letter spacing Keystone UI's text sizes give, and
     the table's head and body fills, header weight, divider and border, in
     light mode and the host's default look. A token the host's own stylesheet
     changes reaches the PDF the same way. A Keystone UI token the stylesheet
     does not set, or sets to a colour or length the gem cannot read, refuses
     the PDF with a message naming the token.

   The choice is a setting in the settings file, written in the next step.

   With the Ruby drawing, check the fonts the host's stylesheet uses:

   - A font named only by system fonts, with no `@font-face`, prints in
     Helvetica and needs nothing. Helvetica draws only Windows-1252 characters,
     so text holding any other character refuses the PDF with a message naming
     the element and the character. If the host's pages will hold such
     characters, such as non-Latin scripts, ask the developer which font to
     serve as TrueType copies that holds them.
   - A font the stylesheet loads with `@font-face` needs a TrueType copy of each
     of its files, because a PDF cannot read `.woff2` or `.woff`. Put a `.ttf`
     file beside each font file, under the same name, either in `public/` or in
     the asset paths Propshaft serves:

     ```
     public/InterVariable.woff2
     public/InterVariable.ttf
     public/InterVariable-Italic.woff2
     public/InterVariable-Italic.ttf
     ```

     Regular, bold and italic text print from the copies whose `@font-face`
     rules give those weights and styles. A PDF asked for in a font with no
     TrueType copy served is refused with a message naming the font and the
     file it looked for. If the host has no `.ttf` files for its font, ask the
     developer where to get them rather than converting or replacing the font.

7. Create `config/initializers/keystone_ui_pages.rb` starting with:

   ```ruby
   require "keystone_ui/pages"
   ```

   Then hand the settings to `keystone_ui-pages-develop`, which owns every one
   of them. Before it writes them, put these questions to the developer, since
   each is a decision about who may see and change what:

   - Which controller the engine's controllers inherit from, normally
     `ApplicationController`. Its filters, such as a sign-in requirement, then
     run on every engine request, including published pages.
   - Who may create, edit and publish pages. With no answer, anyone who can
     reach the page list can.
   - Who may view a published page. With no answer, every published page is
     public.
   - Whether pages belong to an owner, such as the current team. With no
     answer, all pages are shared across the whole app.
   - Which layout each of the two from step 5 uses, and which PDF drawing from
     step 6.

8. Check the install. Boot the app, open the page list at
   `keystone_ui_pages.manage_pages_path`, create a page, add an element in the
   builder, publish it, and open `/pages/<slug>`. With the Chrome drawing, the
   page list shows a PDF link only when Chrome or Chromium was found. With the
   Ruby drawing, it always shows one, so open it on a page holding only
   headings, labels, paragraphs, alerts, label and value lists, buttons,
   accordions, tables and forms to confirm the fonts and text sizes print, each
   label prints in capitals, each alert prints on its type's fill, a
   paragraph's links and a button with an address open their address, each
   accordion question prints with its answer beneath it, each table prints its
   heading row on the table head fill with its item rows beneath it, and the
   form is left out.

   When a PDF link in the page list returns to the list showing a message, the
   PDF was refused, and the message names what to fix: the browser, an
   element, a character, a token or a font from step 6. A refused PDF keeps no
   file, so clicking PDF again after the fix makes a new one. A refusal while
   publishing shows nothing in the page list and reaches only the error
   reporter from step 1.

   Boot stops with an `ArgumentError` naming a place when that place's settings
   are incomplete: it leaves out an element no catalog entry has, it offers the
   Form element with no submissions handler, or it answers sequences with no
   add page method. Fixing the place belongs to `keystone_ui-pages-develop`.

## Conventions

- **Re-run the migration install after upgrading the gem.** A later version can
  add migrations, and they reach the host only through
  `bin/rails keystone_ui_pages:install:migrations` followed by
  `bin/rails db:migrate`.
- **The engine registers itself with Keystone UI's Tailwind build.** On boot it
  appends its views, helpers, JavaScript and Ruby files to Keystone UI's
  Tailwind sources, so the host adds nothing to its Tailwind setup for the
  engine.
- **The engine adds its view helpers to every host view.** No helper include is
  needed in the host.
- **The methods the settings name live on the base controller.** The engine
  calls them on its own controllers, which inherit from it, so a method defined
  anywhere else is not found.
- Every setting, drawing pages, making PDFs, host values, places and the
  catalog are out of scope here and belong to `keystone_ui-pages-develop`.
