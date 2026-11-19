# UNM Marketplace revamp: acceptance specification

**Product:** Nott-A-Marketplace (UNM Marketplace)
**Parent:** Revamp: containers, redesign, own chat, CI/CD (no work item; personal repo)
**Date:** 2026-11-20
**Status:** Draft, awaiting approval (updated 2026-11-20: purpose is a Portfolio showcase)

Design doc: [docs/plans/2026-11-20-revamp-containers-design.md](plans/2026-11-20-revamp-containers-design.md)

Story labels (`RV-01` …) are provisional, not work item IDs. The Gherkin describes expected behaviour, not passing tests.

## Stories at a glance

- **RV-01 Run it anywhere:** one command starts the whole site locally in containers.
- **RV-02 Browse and search:** anyone can find listings fast by search, category, condition, price and sort.
- **RV-03 Account and profile:** students sign up, log in, stay logged in, and manage their profile.
- **RV-04 Sell and manage:** a seller lists an item with photos, edits it, marks it sold or deletes it.
- **RV-05 Saved listings:** a buyer saves listings to come back to.
- **RV-06 Chat:** a buyer messages a seller about a listing in real time, without any outside chat service.
- **RV-07 Ship it:** every push to `main` is checked and, if green, goes live automatically, with rollback.
- **RV-08 Showcase demo:** a recruiter from the Portfolio can try the whole marketplace in one click, and the demo stays tidy.

## Shared definitions and boundaries

- **Visitor:** not logged in. **Student:** logged in. **Owner:** the student who posted a listing.
- **Price** is shown as `RM` with thousands separators and no decimals when whole (`RM 1,234`).
- All identity comes from the login session; nothing the browser sends can make it act as another user.

### Out of scope for all stories
Native app store releases, payments, ratings, admin moderation, email verification, push notifications, migrating 2024 data.

## RV-01: Run it anywhere

**User Story:** As the developer, I want the whole site to start with one command, so that I can run it on any machine or server without setup steps.

### Acceptance criteria
**RV01-AC1: One command.** `docker compose up` on a clean machine starts `web`, `api` and `db`, and the site loads on `http://localhost:8080`.
**RV01-AC2: Data survives restarts.** Listings, photos and logins survive `docker compose down` / `up`.
**RV01-AC3: Health.** `GET /api/health` returns 200 only when the database is reachable.

### Gherkin specifications
```gherkin
@RV01
Feature: Containerised stack

  @RV01_AC1
  Scenario: Fresh start
    Given a machine with Docker and a copy of .env.example as .env
    When I run "docker compose up -d"
    Then http://localhost:8080 shows the browse page
    And the database has the default categories

  @RV01_AC2
  Scenario: Restart keeps data and sessions
    Given I am logged in and have posted a listing with a photo
    When the stack is restarted
    Then my listing and its photo are still shown
    And I am still logged in

  @RV01_AC3
  Scenario: Health reflects the database
    Given the db container is stopped
    When I request GET /api/health
    Then the response status is 503
```

## RV-02: Browse and search

**User Story:** As a visitor, I want to browse and search listings, so that I can find what I need without an account.

### Acceptance criteria
**RV02-AC1: Browse.** The home page shows newest listings first, 24 at a time, loading more on scroll.
**RV02-AC2: Filter and sort.** Search text, category, condition, price range and sort combine; the URL reflects them so the view can be shared.
**RV02-AC3: Detail.** Each listing has its own link `/listing/:id` with gallery, price, condition, description and seller.
**RV02-AC4: Empty and missing.** No results shows "Nothing here yet. Be the first to sell something."; an unknown listing shows a not-found page.

### Gherkin specifications
```gherkin
@RV02
Feature: Browse and search

  Background:
    Given listings exist in several categories

  @RV02_AC1
  Scenario: Newest first with infinite scroll
    When I open the home page
    Then I see 24 listings, newest first
    When I scroll to the bottom
    Then the next 24 listings load

  @RV02_AC2
  Scenario Outline: Combined filters
    When I search "<q>" in "<category>" sorted by "<sort>"
    Then every result matches "<q>" and is in "<category>"
    And results are ordered by "<sort>"
    And the address bar contains the filters
    Examples:
      | q    | category    | sort               |
      | lamp | Home & Garden | Price low to high |
      | book | Books       | Newest             |

  @RV02_AC3
  Scenario: Shareable listing page
    When I open /listing/<id> directly in a new tab
    Then I see that listing's gallery, price, condition, description and seller

  @RV02_AC4
  Scenario: Unknown listing
    When I open /listing/999999
    Then I see "This listing doesn't exist or was removed."
```

## RV-03: Account and profile

**User Story:** As a student, I want an account, so that I can sell, save and chat.

### Acceptance criteria
**RV03-AC1: Sign up.** Name, username, email, phone and password (8+ characters) create an account and log me in. A taken email shows "That email is already registered."
**RV03-AC2: Log in / out.** Wrong details show "Email or password is wrong." After 10 failed attempts in 15 minutes from one address, further attempts are refused for a while.
**RV03-AC3: Profile.** I can change my name, phone and photo, and change my password by giving the current one.
**RV03-AC4: Protected actions.** A visitor who tries to sell, save or message is sent to log in and then returned to what they were doing.

### Gherkin specifications
```gherkin
@RV03
Feature: Accounts

  @RV03_AC1
  Scenario: Duplicate email
    Given an account exists for "a@nottingham.edu.my"
    When I sign up with "a@nottingham.edu.my"
    Then I see "That email is already registered."

  @RV03_AC2
  Scenario: Wrong password
    When I log in with a wrong password
    Then I see "Email or password is wrong."

  @RV03_AC3
  Scenario: Change password needs current password
    Given I am logged in
    When I change my password giving the wrong current password
    Then the password is not changed

  @RV03_AC4
  Scenario: Redirect back after login
    Given I am a visitor on a listing page
    When I press "Message seller"
    Then I am asked to log in
    And after logging in I am back on that listing with the chat open
```

## RV-04: Sell and manage

**User Story:** As a student, I want to post and manage listings, so that I can sell things on campus.

### Acceptance criteria
**RV04-AC1: Post.** Photos (1 to 6; JPEG, PNG or WebP; 5 MB each), title, price, category, condition and description publish a listing. Success shows "Your listing is live."
**RV04-AC2: Owner only.** Only the owner can edit, mark as sold or delete; anyone else gets refused, even calling the API directly.
**RV04-AC3: Photos.** The owner can add, remove and reorder photos; the first is the cover.
**RV04-AC4: Sold.** A sold listing shows a "Sold" badge, leaves the default browse results and can no longer be messaged about.

### Gherkin specifications
```gherkin
@RV04
Feature: Selling

  @RV04_AC1
  Scenario: Reject a bad photo
    Given I am posting a listing
    When I add a 12 MB photo
    Then I see "Photos must be JPEG, PNG or WebP, up to 5 MB."

  @RV04_AC2
  Scenario: Someone else's listing
    Given a listing owned by another student
    When I send PATCH /api/listings/<id>
    Then the response status is 403
    And the listing is unchanged

  @RV04_AC4
  Scenario: Mark as sold
    Given I own a listing
    When I mark it as sold
    Then it shows a "Sold" badge
    And it no longer appears in default browse results
```

## RV-05: Saved listings

**User Story:** As a student, I want to save listings, so that I can find them again.

### Acceptance criteria
**RV05-AC1: Toggle.** The heart on a card or detail page saves or unsaves; saving twice keeps one entry.
**RV05-AC2: Saved page.** "Saved" lists my saved listings newest-saved first; deleted listings disappear from it.

### Gherkin specifications
```gherkin
@RV05
Feature: Saved listings

  @RV05_AC1
  Scenario: Save is idempotent
    Given I am logged in
    When I save the same listing twice
    Then it appears once on my Saved page

  @RV05_AC2
  Scenario: Deleted listing leaves Saved
    Given I saved a listing
    When its owner deletes it
    Then it is no longer on my Saved page
```

## RV-06: Chat

**User Story:** As a buyer, I want to message a seller about a listing, so that we can agree a deal.

### Acceptance criteria
**RV06-AC1: Start.** "Message seller" opens the one conversation for me and that listing (creating it the first time). Owners can't message themselves.
**RV06-AC2: Real time.** Messages appear for the other person within 2 seconds without a refresh; a typing indicator shows while they type.
**RV06-AC3: Inbox.** Messages lists my conversations, latest first, with the listing photo, last message and unread count; opening one marks it read.
**RV06-AC4: Private.** Only the two people in a conversation can read or send in it.
**RV06-AC5: History.** Older messages load when scrolling up; messages survive restarts.

### Gherkin specifications
```gherkin
@RV06
Feature: Chat

  Background:
    Given buyer "amy" and seller "ben" who owns listing "Desk lamp"

  @RV06_AC1
  Scenario: Same conversation reused
    When amy presses "Message seller" on "Desk lamp" twice
    Then only one conversation exists between amy and ben for "Desk lamp"

  @RV06_AC2
  Scenario: Live delivery
    Given ben has the conversation open
    When amy sends "Still available?"
    Then ben sees "Still available?" within 2 seconds

  @RV06_AC3
  Scenario: Unread badge
    Given ben is on another page
    When amy sends a message
    Then ben's Messages tab shows 1 unread

  @RV06_AC4
  Scenario: Outsider is refused
    Given student "cat" is not in the conversation
    When cat requests its messages
    Then the response status is 403
```

## RV-07: Ship it

**User Story:** As the developer, I want every push to `main` checked and deployed automatically, so that the live site is always the latest working version.

### Acceptance criteria
**RV07-AC1: Checks on PRs.** Lint, tests and both image builds run on every PR and push.
**RV07-AC2: Deploy on green.** On `main`, images tagged with the commit are published and the VM switches to them.
**RV07-AC3: Safe failure.** If checks fail nothing is deployed; if the new version fails its health check the previous version is restored.
**RV07-AC4: Rollback.** Running the workflow by hand with an older tag deploys that version.

### Gherkin specifications
```gherkin
@RV07
Feature: CI/CD

  @RV07_AC3
  Scenario: Failing test blocks deploy
    Given a commit on main with a failing test
    Then the deploy job does not run
    And unm.junkit.my keeps serving the previous version

  @RV07_AC3
  Scenario: Unhealthy release is rolled back
    Given a release whose api fails /api/health
    When it is deployed
    Then the previous image tag is redeployed
    And the workflow run is marked failed
```

## RV-08: Showcase demo

**User Story:** As someone arriving from Jun Kit's Portfolio, I want to try the marketplace instantly, so that I can see what it does without signing up.

### Acceptance criteria
**RV08-AC1: Full from the start.** A fresh stack already shows about 30 demo listings with photos across every category.
**RV08-AC2: One-click demo.** "Try the demo" creates a fresh guest buyer and logs them in, with one saved listing and one chat already there. Guests never see other visitors' activity, and can't set a password or delete the account.
**RV08-AC3: Chat comes alive.** Messaging a demo seller shows a typing indicator and then a reply about that listing within about 3 seconds.
**RV08-AC4: Nightly reset.** At 03:00 Malaysia time everything visitors created is removed and the demo data is restored.
**RV08-AC5: Tells the story.** A banner says "Demo site. Data resets nightly. Built by Jun Kit" with a link to the Portfolio, and an About page explains the stack and what was rebuilt.

### Gherkin specifications
```gherkin
@RV08
Feature: Showcase demo

  @RV08_AC2
  Scenario: Try the demo
    Given I am a visitor on the home page
    When I press "Try the demo"
    Then I am logged in as a new guest like "Guest 4821"
    And I see one saved listing and one chat already waiting

  @RV08_AC2
  Scenario: Guests are isolated
    Given two visitors each pressed "Try the demo"
    When the first saves a listing and sends a message
    Then the second visitor sees neither

  @RV08_AC2
  Scenario: Demo account is protected
    Given I am logged in as a guest
    When I open account settings
    Then there is no change-password or delete-account option
    And PUT /api/me/password returns 403

  @RV08_AC3
  Scenario: Demo seller replies
    Given I am logged in as a guest
    When I message the seller of a demo listing "Is this still available?"
    Then I see the seller typing
    And within 3 seconds a reply mentioning the listing title appears

  @RV08_AC4
  Scenario: Nightly reset
    Given a visitor posted a listing and sent messages today
    When the 03:00 reset runs
    Then that listing, its photos and those messages are gone
    And all demo listings are back as seeded
```

## Shared technical completion checks

- No secrets in the repo; `.env.example` documents every variable.
- Backend tests cover every route's happy path, auth (401) and ownership (403).
- `flutter analyze` is clean; widget tests cover browse, detail, sell and chat screens.
- Accessibility: Flutter semantics labels on all interactive widgets; Lighthouse accessibility ≥ 90 is a target checked at the end, not a CI gate.
- Works at 360 px phone width and at 1440 px desktop.

## Project note: safe test environments

Test against the local compose stack. Demo mode (`SEED_DEMO=true`) is on everywhere, including the VM, because the live site is a showcase.
