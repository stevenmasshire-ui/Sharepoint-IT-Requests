# Sharepoint-IT-Requests

A build package for an internal IT ticketing app on Microsoft Power Apps + SharePoint. Staff submit IT requests and track status; IT (you) triages the queue, updates status, asks follow-up questions, and keeps private notes — all in one canvas app backed by two SharePoint lists.

Since Power Apps canvas apps are assembled interactively in Power Apps Studio rather than compiled from source, this repo holds the provisioning script and the full design spec needed to build it:

- [`docs/data-model.md`](docs/data-model.md) — the two SharePoint lists (`IT Requests`, `IT Request Comments`) and their columns
- [`docs/manual-list-setup.md`](docs/manual-list-setup.md) — no-PowerShell, browser-only steps to create the lists (use this if you can't install PowerShell modules)
- [`docs/app-design.md`](docs/app-design.md) — screens, role logic (hardcoded admin emails), and the Power Fx formulas for each control
- [`docs/power-automate-flows.md`](docs/power-automate-flows.md) — the notification flows (new ticket, status change, new comment, optional overdue digest)
- [`docs/build-guide.md`](docs/build-guide.md) — the ordered checklist to assemble everything end to end
- [`provisioning/New-ITRequestLists.ps1`](provisioning/New-ITRequestLists.ps1) — optional PnP PowerShell script that creates the SharePoint lists/columns, if you can run PowerShell somewhere

Start with `docs/build-guide.md`.
