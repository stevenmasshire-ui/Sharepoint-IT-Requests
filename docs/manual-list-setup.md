# Manual List Setup (No PowerShell Required)

If you can't install the `PnP.PowerShell` module (e.g. your work PC blocks PowerShell Gallery installs), skip `provisioning/New-ITRequestLists.ps1` entirely and build both lists by hand in the browser instead. This produces the exact same schema described in `data-model.md` — everything downstream (Power Fx formulas, flows) works identically either way.

**Permission note:** creating lists requires at least the "Design" permission level (or Full Control/site ownership) on the target site. If you only have Contribute/Edit access, ask a site owner to either create the lists for you or bump your permission first.

## 1. Create the `IT Requests` list

1. Go to your SharePoint site → **Site contents** → **+ New → List**.
2. Choose **Blank list**, name it `IT Requests`, create it.
3. Add columns via **+ Add column** at the right end of the header row:

   | Column name | Column type | Setup |
   |---|---|---|
   | Description | Multiple lines of text | Plain text (leave "enhanced rich text" off) |
   | Category | Choice | Choices, one per line: `Hardware`, `Software`, `Access/Account`, `Network`, `Other` |
   | Priority | Choice | Choices, one per line: `Low`, `Medium`, `High`, `Urgent` |
   | Status | Choice | Choices, one per line: `New`, `In Progress`, `Waiting on Requester`, `Resolved`, `Closed`. In the same column settings panel, set **Default value** to `New`. |
   | DueDate | Date and time | Set **Date and Time Format** to "Date Only" |

4. Attachments are on by default — no column needed. To double-check: **List settings → Advanced settings → Attachments** should show "Enabled."

## 2. Create the `IT Request Comments` list

1. **Site contents** → **+ New → List → Blank list**, name it `IT Request Comments`.
2. Add columns:

   | Column name | Column type | Setup |
   |---|---|---|
   | RequestID | Lookup | Click **+ Add column → More column types...** (Lookup isn't in the quick-add menu) → **Type: Lookup** → "Get information from": `IT Requests` → "In this column": `Title` |
   | CommentText | Multiple lines of text | Plain text |
   | IsInternalNote | Yes/No | Set **Default value** to `No` |

## 3. Verify

Open both lists and confirm the columns/types/choices match this list and `docs/data-model.md` exactly — a typo in a Choice value (e.g. `Access/Account` vs `Access-Account`) will silently break any Power Fx or flow condition that references it by exact string.

Once both lists look right, continue with `build-guide.md` step 2 (creating the canvas app in Power Apps Studio).
