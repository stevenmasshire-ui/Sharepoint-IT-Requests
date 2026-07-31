# Canvas App Design

Build a **Canvas App** (not model-driven) with both `IT Requests` and `IT Request Comments` added as SharePoint data sources.

## Role model — hardcoded admin emails

No SharePoint group is used. The admin list lives directly in the app as a formula, so "adding an IT teammate" means editing one line in `App.OnStart` and republishing.

**`App.OnStart`:**
```powerfx
Set(
    gblAdminEmails,
    ["sdmctosh@gmail.com"]   // add more admin addresses here, comma-separated
);
Set(
    gblIsAdmin,
    !IsBlank(
        LookUp(gblAdminEmails, Value = Lower(User().Email))
    )
);
```
*(If `gblAdminEmails` is a plain text collection, `LookUp` over a single-column table works via `Value`; alternatively use `CountRows(Filter(gblAdminEmails, Lower(Value) = Lower(User().Email))) > 0`.)*

Every screen reads `gblIsAdmin` to decide what to show — there is no separate "admin app," it's one app with conditional visibility.

## Screens

### 1. Home
- Two views toggled by a top control (buttons or a `Tab` control), both hidden/shown by role:
  - **"My Requests"** (always visible): gallery bound to
    ```powerfx
    SortByColumns(
        Filter('IT Requests', Author().Email = User().Email),
        "Modified", Descending
    )
    ```
    Each row shows `Title`, a colored `Status` pill, `Priority`, and `Modified`.
  - **"All Requests"** (`Visible: gblIsAdmin`): gallery over the full list with filter controls bound to dropdowns for `Status`, `Priority`, `Category`, plus a search box (`Filter('IT Requests', StartsWith(Title, TextSearchBox1.Text))` combined with the dropdown filters via `And(...)`).
- A "+ New Request" button navigates to the **New Request** screen.

### 2. New Request
- A standard `Edit Form` (`Form1`) bound to `IT Requests`, `DefaultMode: FormMode.New`, with `DataCard`s for `Title`, `Description`, `Category`, `Priority`, and the `Attachments` control.
- `Status` is **not** on the form — set it on submit so every new ticket starts as `New`:
  ```powerfx
  // Submit button OnSelect
  Patch(
      'IT Requests',
      Defaults('IT Requests'),
      Concat(BlankCollection, "") // placeholder, real fields come from the form
  );
  ```
  In practice, use `SubmitForm(Form1)` and set `Status` via the form's `Item` default or an `Updates` object on a hidden `DataCard`, e.g. add an unlocked `Status` DataCard defaulted to `"New"` and hidden with `Visible: false`.
- On success (`Form1.OnSuccess`): `Navigate(Home)` with a confirmation banner/notification.

### 3. Request Detail
Navigated to with `Navigate(RequestDetail, ScreenTransition.Cover, {selectedTicket: ThisItem})` from either gallery, and also reachable via deep link (see below).

- **Header** (read-only): `Title`, `Description`, `Category`, `Priority`, `Status` badge, `DueDate`, `Attachments` gallery.
- **Admin-only edit controls** (`Visible: gblIsAdmin`):
  - `Status` dropdown → `OnChange`: `Patch('IT Requests', selectedTicket, {Status: StatusDropdown.Selected.Value})`
  - `Priority` dropdown and `DueDate` date picker, same `Patch`-on-change pattern.
- **Conversation thread** (visible to everyone, staff and admin):
  ```powerfx
  SortByColumns(
      Filter('IT Request Comments', RequestID.Id = selectedTicket.ID, IsInternalNote = false),
      "Created", Ascending
  )
  ```
  Below the gallery, a text input (`NewCommentInput`) + **Send** button:
  ```powerfx
  // Send button OnSelect
  Patch(
      'IT Request Comments',
      Defaults('IT Request Comments'),
      {
          RequestID: selectedTicket,
          CommentText: NewCommentInput.Text,
          IsInternalNote: false
      }
  );
  Reset(NewCommentInput);
  ```
- **Internal Notes panel** (`Visible: gblIsAdmin` — never rendered for staff, this is the privacy boundary):
  ```powerfx
  SortByColumns(
      Filter('IT Request Comments', RequestID.Id = selectedTicket.ID, IsInternalNote = true),
      "Created", Ascending
  )
  ```
  Its own text input + **Add Note** button, identical `Patch` pattern but `IsInternalNote: true`.

## Deep linking (for email notifications)

Add to `App.OnStart` (after the admin-check block):
```powerfx
If(
    !IsBlank(Param("ticketId")),
    Set(deepLinkTicket, LookUp('IT Requests', ID = Value(Param("ticketId"))));
    Navigate(RequestDetail, ScreenTransition.None, {selectedTicket: deepLinkTicket})
);
```
Power Automate builds the link as the app's play URL plus `&ticketId=123` (see `power-automate-flows.md`), so an email notification opens straight to the right ticket.
